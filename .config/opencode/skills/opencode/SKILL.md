---
name: opencode
description: Use when developing plugins, tools, and extensions for OpenCode v1 - plugin contract and crash-prevention rules, ctx and event APIs, subagent lifecycle, MCP integration, SDK usage, REST API, testing, or publishing to npm
metadata:
  author: mte90
  version: 3.1.0
  tags:
    - opencode
    - plugin
    - ai-agent
    - mcp
    - tool-development
---

# OpenCode Plugin Development

Complete, field-tested guide for developing plugins for OpenCode (v1.18+) AI coding agent.

> **Every rule, signature, and pattern below was verified against a real plugin
> (`opencode-auto-resume`) that went through 5 versions and 3 distinct crash
> classes in production.** The "Hard-won rules" sections are non-negotiable —
> violating them silently breaks the host.

---

## Extension Types — When to Use What

| Extension Type | Best For | Example |
|----------------|----------|---------|
| **Plugin (Hooks)** | Event-driven automation, custom tools, recovery logic | Auto-resume stalled sessions, enforce agent selection |
| **Tools** | AI-triggered actions inside a plugin | `task_complete`, `commit`, custom search |
| **MCP Servers** | External service integrations | Databases, GitHub, filesystem, remote APIs |
| **Skills** | Knowledge/prompt templates (this file is one) | Framework patterns, project conventions |
| **Commands** | Interactive slash shortcuts | `/hello`, `/deploy` |
| **Providers** | Custom LLM backends | Alternative API gateways, self-hosted models |

---

## The Plugin Contract (v1.18+) — Read This First

A plugin is an **async function** `(input, Options) => Promise<Hooks>`. It is NOT an object with `name`/`version`/`tools` fields — that shape is outdated and the host ignores it.

### Type definition (from `@opencode-ai/plugin/dist/index.d.ts`)

```typescript
export type Plugin = (input: PluginInput, options?: PluginOptions) => Promise<Hooks>

export interface Hooks {
  dispose?: () => Promise<void>
  event?: (input: { event: Event }) => Promise<void>
  config?: (input: Config) => Promise<void>
  tool?: { [key: string]: ToolDefinition }
  auth?: AuthHook
  provider?: ProviderHook
  "chat.message"?: (input: ChatMessageInput) => Promise<void>
  "tool.execute.before"?: (input: ToolExecInput) => Promise<void>
  "tool.execute.after"?: (input: ToolExecInput) => Promise<void>
  "command.execute.before"?: (input: CommandExecInput) => Promise<void>
  "command.execute.after"?: (input: CommandExecInput) => Promise<void>
}
```

### Correct minimal plugin

```typescript
import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async (ctx, options) => {
  return {
    event: async ({ event }) => {
      // handle events
    },
    config: async () => {
      // one-time init
    },
    tool: {
      my_tool: tool({
        description: "Does something useful",
        args: {},
        execute: async (_args, ctx) => "ok",
      }),
    },
  }
}

export default MyPlugin
```

> ⚠️ **`config` hook signature**: `(input: Config) => Promise<void>`. It receives a Config object — you may ignore it but the parameter exists.

---

## 🚨 Hard-Won Rules (violate these and the host crashes)

These rules were discovered through real production crashes. Each one has a regression test in the reference plugin.

### Rule 1 — Only export Plugin-shaped values from the entry module

OpenCode's plugin loader iterates **every** module export via `Object.values(module)` and treats each as a Plugin entrypoint:

```js
// Inside opencode's plugin loader (deobfuscated):
for (let N of Object.values(pluginModule)) {
  if (typeof N !== "function") throw TypeError("Plugin export is not a function")
  const hooks = await N(ctx, options)   // called as a Plugin!
  pluginArray.push(hooks)
}
// later:
for (let N of pluginArray) {
  await N.config?.(config)   // crashes if N is null
}
```

**If any export returns `null` → the host crashes with `null is not an object (evaluating 'N.config')`, surfaced in the TUI as `Unexpected server error. Check server logs for details.`**

#### ✅ Correct

```typescript
// src/index.ts — ONLY Plugin exports
export const MyPlugin: Plugin = async (ctx, options) => { ... }
export default MyPlugin
```

#### 🚫 Wrong — crashes the host

```typescript
// src/index.ts
export function getLastAssistantError(messages) { ... return null }  // called as Plugin, returns null, host crashes
export function backoffMs(attempt) { return 42 }                       // called as Plugin, returns number, host crashes
export const MyPlugin: Plugin = async (ctx, options) => { ... }
export default MyPlugin
```

#### Solution — split utilities into a separate file

```typescript
// src/index.ts — bundle entry, only Plugin exports
export const MyPlugin: Plugin = async (ctx, options) => { ... }
export default MyPlugin

// src/test-utils.ts — NOT the bundle entry; tests import from here
export function getLastAssistantError(messages) { ... }
export function backoffMs(attempt, base, max) { ... }
```

Tests import utilities from `./test-utils`; the bundled `dist/index.js` only exposes the Plugin. Verify with:

```bash
bun -e 'const m = await import("./dist/index.js"); console.log(Object.keys(m))'
# MUST print only: [ "MyPlugin", "default" ]
```

### Rule 2 — Never let an async handler throw unhandled

The `event` hook is called **fire-and-forget** by the host. If `handleEvent()` rejects, it becomes an unhandled promise rejection → bun process exits → OpenCode disappears from the TUI.

#### ✅ Correct

```typescript
return {
  event: async ({ event }) => {
    handleEvent(event).catch((e) => {
      console.error("[my-plugin] handleEvent error:", e)
    })
  },
}
```

Same rule applies to `setInterval(async () => { ... })` bodies — wrap in a `safe()` boundary:

```typescript
async function safe<T>(fn: () => Promise<T>, label: string): Promise<T | undefined> {
  try { return await fn() }
  catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    console.error(`[my-plugin] ${label}: ${msg}`)
    return undefined
  }
}

setInterval(() => {
  safe(doPeriodicWork, "periodic timer").catch(() => {})
}, 5000)
```

### Rule 3 — Validate event payloads defensively

OpenCode event payloads are **not guaranteed** to match the documented shape. Real-world crashes found:

- `todo.updated` events arrive with `properties.todos` as `{}` (object) or `undefined`, not an array
- `session.status` `properties.status` is always `{ type: "idle" | "busy" | "retry" }` — never a bare string
- Session IDs (`sessionID`) may be missing on some events

#### ✅ Correct — `Array.isArray` before `.map()`/`.filter()`

```typescript
case "todo.updated": {
  const rawTodos = (event.properties as any)?.todos
  const todos: Array<Record<string, unknown>> = Array.isArray(rawTodos) ? rawTodos : []
  w.todos = todos.map((t) => ({ ... }))   // safe
  break
}
```

### Rule 4 — `log()` must never rethrow

If the OpenCode log API itself throws (network/server error), your `log()` helper's `catch` block must not propagate. Otherwise an error inside an error handler escapes:

```typescript
async function log(level: "info" | "warn" | "error", msg: string) {
  try {
    await ctx.client.app.log({ body: { service: "my-plugin", level, message: msg } })
  } catch (e) {
    console.error("[my-plugin] log() failed:", e instanceof Error ? e.message : e)
    // do NOT rethrow
  }
}
```

### Rule 5 — Validate `sid` before every SDK call

Session IDs from events may be empty, `undefined`, or malformed. The SDK throws `Expected 'id' to be a string` if you pass garbage:

```typescript
if (typeof sid !== "string" || !sid.startsWith("ses_")) return
await ctx.client.session.prompt({ path: { id: sid }, body: { ... } })
```

---

## The Context API (`ctx`)

The `ctx` parameter is undocumented but stable across v1.18.x:

```typescript
// ctx.client — API calls
await ctx.client.app.log({
  body: { service: "my-plugin", level: "info", message: "..." }
})

const { data: sessions } = await ctx.client.session.list()
const { data: statusMap } = await ctx.client.session.status()  // Record<sid, {type: "busy"|"idle"|"retry"}>
const messages = await ctx.client.session.messages({ path: { id: sid } })
await ctx.client.session.abort({ path: { id: sid } })
await ctx.client.session.prompt({
  path: { id: sid },
  body: {
    parts: [{ type: "text", text: "continue" }],
    agent,   // optional: preserve selected agent
    model,   // optional: { providerID, modelID }
  },
})

// ctx.ui — toast notifications (TUI)
await ctx.ui.toast({ title: "Done", message: "...", variant: "success" })
```

### `session.status()` return shape

```typescript
// status() returns { data: Record<sid, status> } where status is:
type SessionStatus = { type: "idle" | "busy" | "retry" }
// NEVER a bare string — always access via .type
```

### `session.list()` does NOT include status

The `Session` type from `session.list()` has **no** `status` field. To check if a session is busy, call `session.status()` separately and build a `Record<sid, string>` map.

---

## Event System

Plugins receive Server-Sent Events via the `event` hook. Real event types (v1.18+):

```typescript
return {
  event: async ({ event }) => {
    const type = event.type as string
    const sid = event.sessionID as string | undefined
    const props = event.properties as Record<string, unknown> | undefined

    switch (type) {
      case "session.created":
      case "session.updated":
      case "session.idle":          // legacy alias of session.status=idle
      case "session.interrupted":   // user pressed ESC
        break

      case "session.status": {
        const status = props?.status as { type: string } | undefined
        // status.type in "idle" | "busy" | "retry" | "interrupted"
        break
      }

      case "session.error": {
        const error = props?.error as { name: string; data?: { message: string } } | undefined
        // error.name === "MessageAbortedError" → user pressed ESC
        break
      }

      case "message.updated":
      case "message.part.updated":
        // props?.delta — streaming text delta
        break

      case "todo.updated": {
        // ⚠️ props?.todos may be {} or undefined — validate with Array.isArray
        break
      }

      case "tool.call":
      case "tool.result":
      case "command.executed":
        break
    }
  },
}
```

---

## Deep Dives

The following reference files contain detailed documentation on specific topics. They are loaded on demand from `../SKILL.md`:

- **Subagents & Tools** — Subagent lifecycle management, timeout patterns, abort handling, tool system API → [`references/subagents-tools.md`](references/subagents-tools.md)
- **MCP, SDK & HTTP API** — MCP integration, SDK client usage, REST endpoints, server configuration → [`references/mcp-sdk-api.md`](references/mcp-sdk-api.md)
- **Testing & Real-World Patterns** — Testing strategies, SDK types, debugging, production patterns → [`references/testing-patterns.md`](references/testing-patterns.md)
- **Configuration & Publishing** — Plugin installation, options pattern, build config, npm distribution → [`references/config-publishing.md`](references/config-publishing.md)

---

## Debugging

### "Unexpected server error. Check server logs for details."

This is the generic TUI mask. The real error is in the log:

```bash
grep "level=ERROR" ~/.local/share/opencode/log/opencode.log | tail -20
```

Common causes (in order of likelihood):

1. **Non-Plugin export returns null** → `null is not an object (evaluating 'N.config')` — see Rule 1
2. **Unhandled promise rejection** in `event` hook or `setInterval` — see Rule 2
3. **Event payload not validated** → `todos.filter is not a function` — see Rule 3
4. **Invalid session ID** passed to SDK → `Expected 'id' to be a string` — see Rule 5

### Plugin not loading

```bash
grep "failed to load plugin" ~/.local/share/opencode/log/opencode.log
```

Check:
- `dist/index.js` exists and has `"main": "dist/index.js"` in `package.json`
- The cache directory has the real package, not just a wrapper: `ls ~/.cache/opencode/packages/<name>@<ver>/node_modules/<name>/dist/index.js`
- `bun.lock` in `~/.config/opencode/` resolves to the version you expect

### Verify which version loaded at runtime

```bash
grep "opencode-auto-resume\|my-plugin" ~/.local/share/opencode/log/opencode.log | tail -5
# Look for: path=my-plugin@X.Y.Z
```

---

## Summary Checklist

Before publishing a plugin:

- [ ] `dist/index.js` exports ONLY `default` (and optionally a named alias of the same function)
- [ ] `event` hook wraps async work in `.catch()`
- [ ] All `setInterval` async bodies wrapped in try/catch or `safe()`
- [ ] `log()` helper never rethrows
- [ ] All event payload fields validated (`Array.isArray`, `typeof`, `?.`)
- [ ] All SDK calls validate `sid` first
- [ ] `session.status()` accessed via `.type`, never compared as bare string
- [ ] Tests include source-contract assertions (not just behavioral)
- [ ] `bun test` passes with 0 failures
- [ ] `bun build` produces `dist/index.js` with only Plugin exports