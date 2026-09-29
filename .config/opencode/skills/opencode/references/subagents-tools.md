<!-- Loaded on demand from ../SKILL.md -->

# Subagent Lifecycle Management & Tool System

## Subagent Lifecycle Management

Managing subagents spawned from plugins requires careful attention to timeouts, abort handling, and cleanup to prevent runaway processes.

### Spawning Subagents

Use `ctx.client.session.create` with subagent configuration:

```typescript
const subagent = await ctx.client.session.create({
  parentID: ctx.session.id,
  agent: "fixer",
  message: "Fix the failing tests in auth.ts",
})
```

### Timer-Based Abort

The critical pattern for preventing runaway subagents:

```typescript
const TIMEOUT_MS = 60000 // 60 seconds

const subagent = await ctx.client.session.create({ 
  parentID: ctx.session.id,
  agent: "fixer",
  message: "Fix failing tests",
})

const timer = setTimeout(async () => {
  try {
    await ctx.client.session.abort({ id: subagent.id })
    ctx.logger.warn(`Subagent ${subagent.id} aborted after timeout`)
  } catch (error) {
    ctx.logger.error(`Failed to abort subagent: ${error}`)
  }
}, TIMEOUT_MS)

// Clear timer when subagent completes
ctx.client.session.subscribe(subagent.id, (event) => {
  if (event.type === "session.end" || event.type === "session.error") {
    clearTimeout(timer)
  }
})
```

### Abort API

Use `ctx.client.session.abort({ id })` to terminate a subagent:

```typescript
try {
  await ctx.client.session.abort({ id: subagent.id })
  ctx.logger.info(`Subagent ${subagent.id} aborted successfully`)
} catch (error) {
  // Abort may throw if session already ended
  ctx.logger.warn(`Subagent ${subagent.id} already ended: ${error}`)
}
```

### State Polling

Check subagent status:

```typescript
const status = await ctx.client.session.get({ id: subagent.id })
if (status.status === "completed") {
  // Process results
  const messages = await ctx.client.session.messages({ id: subagent.id })
  // ... process messages
} else if (status.status === "running") {
  // Still working
} else if (status.status === "aborted") {
  // Was terminated
}
```

### Cleanup on Abort

When a subagent is aborted mid-execution, clean up resources:

```typescript
async function spawnWithCleanup(ctx: any, config: SubagentConfig) {
  const subagent = await ctx.client.session.create(config)
  const tempFiles: string[] = []
  
  // Register cleanup handler
  const cleanup = async () => {
    for (const file of tempFiles) {
      await ctx.client.fs.remove({ path: file }).catch(() => {})
    }
  }
  
  ctx.client.session.subscribe(subagent.id, async (event) => {
    if (event.type === "session.end" || event.type === "session.error" || event.type === "session.aborted") {
      await cleanup()
    }
  })
  
  return { subagent, cleanup }
}
```

### Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Subagent hangs forever | No timeout set | Always set a timer with abort |
| Timer fires after completion | Not cleared on success | Clear timer in completion handler |
| Abort throws | Session already ended | Wrap abort in try/catch |
| Parent waits forever | No abort on parent exit | Register cleanup handler on parent end |

---

## Tool System

Use the `tool()` factory from `@opencode-ai/plugin`. Do NOT hand-roll a `Tool` object.

```typescript
import { tool } from "@opencode-ai/plugin"
import { z } from "zod"  // or omit args for no-arg tools

const myTool = tool({
  description: "Search the codebase for a pattern",
  args: z.object({
    query: z.string().describe("Search query"),
    maxResults: z.number().optional().default(10),
  }),
  execute: async (args, ctx) => {
    // args is typed from the schema
    // ctx.sessionID — the session that called the tool
    return `Found ${args.maxResults} results for "${args.query}"`
  },
})
```

For no-arg tools:

```typescript
const taskCompleteTool = tool({
  description: "Signal that all work is complete",
  args: {},
  execute: async (_args, ctx) => "Task completion acknowledged",
})
```

Register tools in the `tool` hook:

```typescript
return {
  tool: {
    task_complete: taskCompleteTool,
    my_search: myTool,
  },
}
```