---
name: opencode-plugin
description: "Develop plugins, tools, and extensions for OpenCode AI coding agent with MCP, LSP integration, custom tools, and SDK usage"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
  tags:
    - opencode
    - plugin
    - ai-agent
    - mcp
    - tool-development
---

# OpenCode Plugin Development

Complete guide for developing plugins, tools, and extensions for OpenCode AI coding agent.

## Overview

OpenCode is an AI-powered coding agent that supports extensibility through plugins, custom tools, MCP (Model Context Protocol) servers, and skills.

### Repository Structure

```
anomalyco/opencode/
├── packages/
│   ├── opencode/          # Main CLI and server
│   │   └── src/
│   │       ├── plugin/    # Plugin system
│   │       ├── tool/      # Tool system
│   │       ├── mcp/       # MCP integration
│   │       ├── session/   # Session management
│   │       └── provider/  # LLM providers
│   ├── plugin/            # Plugin API package
│   │   └── src/           # @opencode-ai/plugin
│   ├── sdk/               # SDK packages
│   │   └── js/            # @opencode-ai/sdk (TypeScript)
│   └── util/              # Shared utilities
```

### Extension Points

1. **Tools**: Functions the AI can call to perform actions
2. **MCP Servers**: External services exposing tools via MCP protocol
3. **Skills**: Prompt templates and knowledge (SKILL.md files)
4. **Commands**: Custom slash commands
5. **Providers**: Custom LLM provider integrations

## Plugin System

### Plugin Package (@opencode-ai/plugin)

```typescript
// packages/plugin/src/index.ts
export interface Plugin {
  name: string
  version: string
  description?: string
  tools?: Tool[]
  commands?: Command[]
  providers?: Provider[]
  skills?: Skill[]
}

export interface Tool {
  name: string
  description: string
  parameters: Schema
  execute: (args: any, context: ToolContext) => Promise<ToolResult>
}

export interface ToolContext {
  session: Session
  provider: Provider
  config: Config
  fs: FileSystem
}

export interface ToolResult {
  content: string | ContentBlock[]
  isError?: boolean
}
```

### Creating a Plugin

```typescript
// my-plugin/index.ts
import { Plugin, Tool } from '@opencode-ai/plugin'

const myPlugin: Plugin = {
  name: 'my-custom-plugin',
  version: '1.0.0',
  description: 'Custom tools for OpenCode',
  
  tools: [
    {
      name: 'my_tool',
      description: 'Performs a custom action',
      parameters: {
        type: 'object',
        properties: {
          input: {
            type: 'string',
            description: 'Input to process'
          }
        },
        required: ['input']
      },
      execute: async (args, context) => {
        // Tool implementation
        const result = processInput(args.input)
        return {
          content: result
        }
      }
    }
  ]
}

export default myPlugin
```

## Tool System

### Tool Definition

```typescript
// Tool interface
interface Tool {
  // Unique identifier
  name: string
  
  // Description for the AI model
  description: string
  
  // JSON Schema for parameters
  parameters: JSONSchema
  
  // Handler function
  execute: (args: Record<string, any>, context: ToolContext) => Promise<ToolResult>
}

// Parameter schema example
const toolSchema = {
  type: 'object',
  properties: {
    filePath: {
      type: 'string',
      description: 'Path to the file'
    },
    content: {
      type: 'string',
      description: 'Content to write'
    },
    encoding: {
      type: 'string',
      enum: ['utf-8', 'binary'],
      default: 'utf-8'
    }
  },
  required: ['filePath', 'content']
}
```

### Tool Implementation

```typescript
import { Tool, ToolContext, ToolResult } from '@opencode-ai/plugin'

const searchFilesTool: Tool = {
  name: 'search_files',
  description: 'Search for files matching a pattern',
  
  parameters: {
    type: 'object',
    properties: {
      pattern: {
        type: 'string',
        description: 'Glob pattern to match files'
      },
      directory: {
        type: 'string',
        description: 'Directory to search in',
        default: '.'
      },
      excludePatterns: {
        type: 'array',
        items: { type: 'string' },
        description: 'Patterns to exclude'
      }
    },
    required: ['pattern']
  },
  
  execute: async (args, context: ToolContext) => {
    const { pattern, directory = '.', excludePatterns = [] } = args
    
    try {
      // Access file system through context
      const files = await context.fs.glob(pattern, {
        cwd: directory,
        ignore: excludePatterns
      })
      
      return {
        content: JSON.stringify(files, null, 2)
      }
    } catch (error) {
      return {
        content: `Error: ${error.message}`,
        isError: true
      }
    }
  }
}
```

### Tool Result Types

```typescript
// String result
const stringResult: ToolResult = {
  content: 'Operation completed successfully'
}

// Error result
const errorResult: ToolResult = {
  content: 'Failed to process file',
  isError: true
}

// Structured content
const structuredResult: ToolResult = {
  content: [
    { type: 'text', text: 'File contents:' },
    { type: 'code', language: 'typescript', code: 'const x = 1' }
  ]
}

// Image result
const imageResult: ToolResult = {
  content: [
    { type: 'image', url: 'file:///path/to/image.png' }
  ]
}
```

### Registering Tools

```typescript
// In plugin definition
export default {
  name: 'my-tools',
  version: '1.0.0',
  tools: [
    searchFilesTool,
    readFileTool,
    writeFileTool
  ]
}

// Or dynamically register
import { registerTool } from '@opencode-ai/plugin'

registerTool({
  name: 'dynamic_tool',
  description: 'Dynamically registered tool',
  parameters: { type: 'object', properties: {} },
  execute: async () => ({ content: 'Dynamic!' })
})
```

## MCP Integration

### What is MCP?

Model Context Protocol (MCP) is a standard protocol for connecting AI models to external tools and data sources.

### MCP Server Configuration

```json
// opencode.json
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-filesystem",
      "args": ["--root", "/home/user/projects"],
      "env": {}
    },
    "github": {
      "command": "mcp-github",
      "args": [],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "database": {
      "command": "mcp-postgres",
      "args": ["postgresql://localhost/mydb"]
    }
  }
}
```

### Creating MCP Server

```typescript
// Custom MCP server
import { Server } from '@modelcontextprotocol/sdk/server'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio'

const server = new Server({
  name: 'my-mcp-server',
  version: '1.0.0'
}, {
  capabilities: {
    tools: {}
  }
})

// Register tools
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'my_tool',
        description: 'My custom tool',
        inputSchema: {
          type: 'object',
          properties: {
            query: { type: 'string' }
          },
          required: ['query']
        }
      }
    ]
  }
})

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params
  
  if (name === 'my_tool') {
    const result = await processQuery(args.query)
    return {
      content: [{ type: 'text', text: result }]
    }
  }
  
  throw new Error(`Unknown tool: ${name}`)
})

// Start server
const transport = new StdioServerTransport()
await server.connect(transport)
```

### MCP Tool Usage

```typescript
// Access MCP tools from OpenCode
import { useMcpTools } from '@opencode-ai/plugin'

const githubTools = await useMcpTools('github')

// List available tools
const tools = await githubTools.list()
// [{ name: 'create_issue', description: '...', inputSchema: {...} }, ...]

// Call a tool
const result = await githubTools.call('create_issue', {
  owner: 'myorg',
  repo: 'myrepo',
  title: 'New Issue',
  body: 'Issue description'
})
```

## Skills & Commands

### Skill Files (SKILL.md)

```markdown
---
name: my-skill
description: "Description of what this skill does"
metadata:
  author: "Author Name"
  version: "1.0.0"
  tags:
    - tag1
    - tag2
---

# My Skill

Instructions for the AI when this skill is loaded.

## Instructions

When asked to perform X:
1. Step 1
2. Step 2
3. Step 3

## Examples

Example usage with code samples.
```

### Custom Commands

```typescript
// Define slash command
interface Command {
  name: string
  description: string
  handler: (args: string[], context: CommandContext) => Promise<void>
}

const myCommand: Command = {
  name: '/mycommand',
  description: 'Execute custom action',
  handler: async (args, context) => {
    // Command implementation
    await context.session.sendMessage('Command executed!')
  }
}

// Register in plugin
export default {
  name: 'my-commands',
  version: '1.0.0',
  commands: [myCommand]
}
```

### Built-in Commands

```
/help          - Show available commands
/clear         - Clear conversation
/reset         - Reset session
/model         - Switch model
/skill         - Load a skill
/config        - View/edit configuration
```

## SDK Usage

### @opencode-ai/sdk

```typescript
import { OpenCodeClient } from '@opencode-ai/sdk'

// Create client
const client = new OpenCodeClient({
  baseUrl: 'http://localhost:3000',
  apiKey: 'your-api-key'
})

// Send message
const response = await client.chat({
  message: 'Explain this code',
  files: ['./src/index.ts']
})

// Stream response
for await (const chunk of client.chatStream({
  message: 'Write a function'
})) {
  process.stdout.write(chunk.content)
}

// Execute tool
const result = await client.executeTool({
  name: 'read_file',
  args: { path: './src/main.ts' }
})

// Create session
const session = await client.createSession({
  model: 'claude-3-opus',
  systemPrompt: 'You are a helpful coding assistant'
})

// Continue conversation
const reply = await session.sendMessage('Add error handling')
```

### SDK Client Options

```typescript
interface ClientOptions {
  // API endpoint
  baseUrl?: string
  
  // Authentication
  apiKey?: string
  
  // Model configuration
  model?: string
  
  // Timeout in milliseconds
  timeout?: number
  
  // Retry configuration
  retries?: number
  
  // Custom headers
  headers?: Record<string, string>
}
```

## HTTP Server & REST API

### Server Configuration

```typescript
// Server setup
import { createServer } from '@opencode-ai/server'

const server = createServer({
  port: 3000,
  host: '0.0.0.0',
  
  // Authentication
  auth: {
    type: 'api-key',
    keys: ['secret-key-1', 'secret-key-2']
  },
  
  // CORS
  cors: {
    origins: ['http://localhost:5173'],
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  },
  
  // Rate limiting
  rateLimit: {
    windowMs: 60000,
    max: 100
  }
})

await server.start()
```

### REST API Endpoints

```typescript
// Chat endpoint
POST /api/chat
{
  "message": "string",
  "session_id": "string?",
  "files": ["string"]?,
  "model": "string?"
}

// Response
{
  "content": "string",
  "session_id": "string",
  "tool_calls": [...]
}

// Streaming
POST /api/chat/stream
// Returns SSE stream

// Tool execution
POST /api/tools/execute
{
  "name": "string",
  "args": { ... }
}

// Session management
GET  /api/sessions
POST /api/sessions
GET  /api/sessions/:id
DELETE /api/sessions/:id

// Models
GET /api/models

// Configuration
GET /api/config
PUT /api/config
```

### API Client Example

```typescript
// Using fetch
const response = await fetch('http://localhost:3000/api/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer your-api-key'
  },
  body: JSON.stringify({
    message: 'Hello, OpenCode!',
    model: 'claude-3-opus'
  })
})

const data = await response.json()
console.log(data.content)
```

## Event Bus

### Publishing Events

```typescript
import { Bus } from '@opencode-ai/plugin'

// Publish event
Bus.publish('session:created', {
  sessionId: 'abc123',
  model: 'claude-3-opus'
})

Bus.publish('tool:executed', {
  toolName: 'read_file',
  args: { path: './src/main.ts' },
  result: '...'
})
```

### Subscribing to Events

```typescript
// Subscribe to events
const unsubscribe = Bus.subscribe('session:created', (event) => {
  console.log('New session:', event.sessionId)
})

// Subscribe to all events
Bus.subscribe('*', (event) => {
  console.log('Event:', event.type, event.data)
})

// Unsubscribe
unsubscribe()
```

### Built-in Events

```typescript
// Session events
'session:created'   // New session created
'session:deleted'   // Session deleted
'session:message'   // Message sent/received

// Tool events
'tool:started'      // Tool execution started
'tool:completed'    // Tool completed successfully
'tool:failed'       // Tool execution failed

// File events
'file:read'         // File read
'file:written'      // File written
'file:deleted'      // File deleted

// Model events
'model:switched'    // Model changed
'model:response'    // Model response received
```

## Configuration

### Configuration File

```json
// opencode.json
{
  "model": "claude-3-opus",
  "temperature": 0.7,
  "maxTokens": 4096,
  
  "providers": {
    "anthropic": {
      "apiKey": "${ANTHROPIC_API_KEY}"
    },
    "openai": {
      "apiKey": "${OPENAI_API_KEY}"
    }
  },
  
  "mcpServers": {
    "filesystem": {
      "command": "mcp-filesystem",
      "args": ["--root", "."]
    }
  },
  
  "tools": {
    "enabled": ["read", "write", "search", "execute"],
    "disabled": ["dangerous_tool"]
  },
  
  "plugins": [
    "./plugins/my-plugin",
    "@opencode-ai/plugin-example"
  ]
}
```

### Environment Variables

```bash
# API Keys
ANTHROPIC_API_KEY=sk-ant-xxx
OPENAI_API_KEY=sk-xxx

# Configuration
OPENCODE_CONFIG_PATH=/path/to/opencode.json
OPENCODE_DATA_DIR=/path/to/data

# Server
OPENCODE_PORT=3000
OPENCODE_HOST=0.0.0.0

# Logging
OPENCODE_LOG_LEVEL=info
```

## Testing Plugins

### Unit Tests

```typescript
// tests/tool.test.ts
import { describe, it, expect, vi } from 'vitest'
import { myTool } from '../src/tools'

describe('myTool', () => {
  it('should process input correctly', async () => {
    const mockContext = {
      session: {},
      fs: {
        readFile: vi.fn().mockResolvedValue('content')
      }
    }
    
    const result = await myTool.execute(
      { input: 'test' },
      mockContext as any
    )
    
    expect(result.content).toContain('processed')
    expect(result.isError).toBeFalsy()
  })
  
  it('should handle errors', async () => {
    const mockContext = {
      fs: {
        readFile: vi.fn().mockRejectedValue(new Error('File not found'))
      }
    }
    
    const result = await myTool.execute(
      { input: 'nonexistent' },
      mockContext as any
    )
    
    expect(result.isError).toBe(true)
  })
})
```

### Integration Tests

```typescript
// tests/integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { OpenCodeClient } from '@opencode-ai/sdk'
import { createServer } from '@opencode-ai/server'

describe('Plugin Integration', () => {
  let server
  let client
  
  beforeAll(async () => {
    server = await createServer({ port: 3001 })
    await server.start()
    
    client = new OpenCodeClient({
      baseUrl: 'http://localhost:3001'
    })
  })
  
  afterAll(async () => {
    await server.stop()
  })
  
  it('should execute custom tool', async () => {
    const result = await client.executeTool({
      name: 'my_custom_tool',
      args: { query: 'test' }
    })
    
    expect(result).toBeDefined()
  })
})
```

## Publishing & Distribution

### Package Structure

```
my-opencode-plugin/
├── package.json
├── tsconfig.json
├── src/
│   └── index.ts
├── dist/
│   └── index.js
└── README.md
```

### package.json

```json
{
  "name": "opencode-plugin-mytool",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "peerDependencies": {
    "@opencode-ai/plugin": "^1.0.0"
  },
  "keywords": [
    "opencode",
    "plugin",
    "ai",
    "coding-assistant"
  ]
}
```

### Publishing to npm

```bash
# Build
npm run build

# Test
npm test

# Publish
npm publish --access public
```

### Local Development

```bash
# Link for local testing
npm link

# In opencode config
{
  "plugins": ["opencode-plugin-mytool"]
}
```

## Best Practices

### 1. Tool Design

```typescript
// Good: Clear description and parameters
const goodTool: Tool = {
  name: 'search_code',
  description: 'Search for code patterns across the project using regex or literal matching',
  parameters: {
    type: 'object',
    properties: {
      pattern: {
        type: 'string',
        description: 'Search pattern (regex supported)'
      },
      filePattern: {
        type: 'string',
        description: 'Glob pattern to filter files (e.g., "*.ts")',
        default: '**/*'
      }
    },
    required: ['pattern']
  },
  execute: async (args, context) => {
    // Implementation
  }
}

// Bad: Vague description
const badTool: Tool = {
  name: 'search',
  description: 'Search',
  parameters: { type: 'object' },
  execute: async () => ({ content: '...' })
}
```

### 2. Error Handling

```typescript
const robustTool: Tool = {
  name: 'safe_tool',
  description: 'Tool with proper error handling',
  parameters: { ... },
  execute: async (args, context) => {
    try {
      // Validate args
      if (!args.required) {
        return {
          content: 'Error: Required parameter missing',
          isError: true
        }
      }
      
      // Execute with timeout
      const result = await Promise.race([
        doWork(args),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Timeout')), 30000)
        )
      ])
      
      return { content: result }
    } catch (error) {
      return {
        content: `Error: ${error.message}`,
        isError: true
      }
    }
  }
}
```

### 3. Security

```typescript
// Validate file paths
const safeReadTool: Tool = {
  name: 'safe_read',
  execute: async (args, context) => {
    const path = resolvePath(args.path)
    
    // Check if path is within project
    if (!isWithinProject(path, context.config.projectRoot)) {
      return {
        content: 'Error: Access denied - path outside project',
        isError: true
      }
    }
    
    // Read file
    const content = await context.fs.readFile(path)
    return { content }
  }
}
```

## References

- **OpenCode Repository**: https://github.com/anomalyco/opencode
- **MCP Documentation**: https://modelcontextprotocol.io/
- **TypeScript SDK**: packages/sdk/js
- **Plugin API**: packages/plugin

---

## Advanced Plugin Development (Practical Guide)

This section covers undocumented behaviors discovered through real plugin development.

### Plugin Export Pattern (NOT in official docs)

The official docs show an object export, but **the real pattern is an async function** that returns hooks:

```typescript
// ACTUAL WORKING PATTERN - not object export
export const AutoResumePlugin = async (ctx: any, options: PluginOptions) => {
    // ctx provides access to OpenCode internals
    return {
        event: async ({ event }: { event: Record<string, unknown> }) => {
            // Handle SSE events
        },
        config: async () => {
            // Called when plugin loads
        }
    }
}

export default AutoResumePlugin
```

### Context API (ctx) - Undocumented

```typescript
// ctx.client - API calls
ctx.client.app.log({ 
    body: { 
        service: string,       // Your plugin name
        level: string,        // "debug" | "info" | "warn" | "error"
        message: string 
    } 
})

ctx.client.session.list()           // Get all sessions
ctx.client.session.messages({ id: string })  // Get session messages
ctx.client.session.prompt({        // Send prompt to session
    path: { id: string },
    body: { parts: Array<{ type: string, text: string }> },
    agent?: string                  // Agent name: "sisyphus", "prometheus"
})
ctx.client.session.abort({ id: string })

// ctx.ui - User interface
ctx.ui.toast({
    title: string,
    message: string,
    variant: "info" | "success" | "warning" | "error",
    duration?: number
})
```

### Agent Selection - CRITICAL

**Where is the agent field?**

- `UserMessage` has `agent: string` field (selected by user)
- `AssistantMessage` does NOT have an agent field

```typescript
// Get selected agent from session messages
async function getSessionAgent(ctx: any, sid: string): Promise<string | undefined> {
    const messages = await ctx.client.session.messages({ id: sid })
    
    // Find most recent user message with agent field
    const reversed = [...messages].reverse()
    const lastUserWithAgent = reversed.find(
        m => m.role === "user" && "agent" in m
    )
    
    const agent = (lastUserWithAgent as any)?.agent
    return typeof agent === "string" && agent.length > 0 ? agent : undefined
}
```

### Event System (Real SSE Events)

The "Event Bus" section uses fake `Bus.publish()` - **the real system uses SSE events**:

```typescript
// Real event hook structure
return {
    event: async ({ event }) => {
        const type = event.type as string
        const props = event.properties as Record<string, unknown> | undefined
        const sessionID = event.sessionID as string | undefined
        
        switch (type) {
            case "session.status": {
                const status = props?.status as any
                if (status?.type === "idle") {
                    // Session finished work
                } else if (status?.type === "busy") {
                    // Session is working
                } else if (status?.type === "retry") {
                    // Retry attempt (has attempt, message, next)
                }
                break
            }
            case "session.error": {
                const error = props?.error as any
                break
            }
            case "message.updated": {
                // Message was updated
                break
            }
            case "message.part.updated": {
                const delta = props?.delta as string | undefined
                // Streaming text delta
                break
            }
        }
    }
}
```

### SessionStatus Types

```typescript
type SessionStatus = 
    | { type: "idle" }
    | { type: "busy" }
    | { type: "retry", attempt: number, message: string, next: number }
```

### Message SDK Types (from @opencode-ai/sdk)

```typescript
interface UserMessage {
    id: string
    sessionID: string
    role: "user"
    time: { created: number }
    agent: string          // SELECTED AGENT - critical for resume
    model: { providerID: string, modelID: string }
    tools?: { [key: string]: boolean }
    system?: string
    summary?: { title?: string, body?: string, diffs: any[] }
}

interface AssistantMessage {
    id: string
    sessionID: string
    role: "assistant"
    time: { created: number, completed?: number }
    error?: any           // Error info if failed
    parentID: string
    modelID: string
    providerID: string
    mode: string
    path: { cwd: string, root: string }
    cost: number
    tokens: { input: number, output: number, reasoning: number, cache: { read: number, write: number } }
    finish?: string        // "stop" | "length" | "error" | "unknown"
}
```

### Part Types

```typescript
type Part = 
    | { type: "text", text: string, synthetic?: boolean }
    | { type: "tool", callID: string, tool: string, state: ToolState }
    | { type: "reasoning", text: string }
    | { type: "file", mime: string, url: string }
    | { type: "agent", name: string }
    | { type: "step-start", snapshot?: any }
    | { type: "step-finish", reason: string, cost: number, tokens: any }
    | { type: "subtask", prompt: string, description: string, agent: string }
    | { type: "retry", attempt: number, error: string }
    | { type: "compaction", auto: boolean }

type ToolState = 
    | { status: "pending", input: any, raw: any }
    | { status: "running", input: any, title?: string, time: { start: number } }
    | { status: "completed", input: any, output: any, title: string, metadata: any, time: { start: number, end: number } }
    | { status: "error", input: any, error: any, time: { start: number, end: number } }
```

### Configuration (inline options)

The official docs show plugin as object, but **options are inline in opencode.jsonc**:

```jsonc
{
    "plugin": [
        "file:///absolute/path/to/dist/index.js",
        { "option": "value", "enabled": true }
    ]
}
```

Options are passed as second parameter to the async function:

```typescript
export const MyPlugin = async (ctx, options: { enabled?: boolean } = {}) => {
    if (options.enabled === false) {
        return { event: async () => {}, config: async () => {} }
    }
    // ... plugin logic
}
```

### Type Validation - CRITICAL

**Always validate inputs before API calls** to prevent "Expected 'id' to be a string" errors:

```typescript
// Bad - will crash if sid is invalid
await ctx.client.session.prompt({ path: { id: sid }, ... })

// Good - defensive validation
const validSid = (typeof sid === "string" && sid.length > 0) ? sid : undefined
const validAgent = (typeof agent === "string" && agent.length > 0) ? agent : undefined

if (validSid) {
    await ctx.client.session.prompt({
        path: { id: validSid },
        body: { parts: [...] },
        agent: validAgent
    })
}
```

### Build Configuration

```json
{
    "scripts": {
        "build": "bun build src/index.ts --outdir dist --target bun",
        "dev": "bun build src/index.ts --outdir dist --target bun --watch",
        "prepublishOnly": "bun run build"
    }
}
```

Output goes to `dist/index.js` - use absolute path in opencode.jsonc:

```jsonc
{
    "plugin": [
        "file:///home/user/project/opencode-auto-resume/dist/index.js",
        { "enabled": true }
    ]
}
```

### Testing Pattern

```typescript
import { mock } from "bun:test"
import type { Session, UserMessage, Message } from "@opencode-ai/sdk"

const createMockContext = () => {
    const promptCalls: Array<{ sid: string; agent?: string }> = []
    
    const ctx = {
        client: {
            app: { log: mock(async () => {}) },
            session: {
                list: mock(async () => ({ data: sessions })),
                messages: mock(async (path) => messages.get(path.id) ?? []),
                prompt: mock(async (cfg) => promptCalls.push({ 
                    sid: cfg.path.id, 
                    agent: cfg.agent 
                })),
                abort: mock(async () => ({}))
            }
        },
        ui: { toast: mock(async () => {}) }
    } as any
    
    return { ctx, promptCalls }
}

test("plugin preserves agent on resume", async () => {
    const { ctx, promptCalls } = createMockContext()
    const hooks = await AutoResumePlugin(ctx, {})
    
    // Trigger event
    await hooks.event({ 
        event: { type: "session.status", sessionID: "s1", 
            properties: { status: { type: "idle" } } 
        } 
    })
    
    // Verify agent was passed
    expect(promptCalls[0]?.agent).toBe("prometheus")
})
```

### Common Bugs Discovered

1. **Wrong message type for agent**: Used `AssistantMessage` instead of `UserMessage`
2. **Missing type validation**: "Expected 'id' to be a string" when session is in error state
3. **Wrong hook format**: Returned object from `ctx.on()` instead of `{ event, config }` hooks
4. **Absolute path required**: Plugin config needs `file:///` + absolute path, not relative

### Real World Patterns

**Auto-resume on idle:**

```typescript
async function handleIdleSession(ctx: any, sid: string) {
    const messages = await ctx.client.session.messages({ id: sid })
    const lastMsg = messages[messages.length - 1]
    
    // Check if last message ends with continuation prompt
    if (lastMsg?.role === "assistant" && shouldAutoContinue(lastMsg)) {
        const agent = await getSessionAgent(ctx, sid)
        await ctx.client.session.prompt({
            path: { id: sid },
            body: { parts: [{ type: "text", text: "continue" }] },
            agent: agent
        })
    }
}

function shouldAutoContinue(msg: Message): boolean {
    const text = (msg as any).parts?.[0]?.text ?? ""
    return text.endsWith("Ready to continue with Task") || 
           text.includes("Should I continue?") ||
           text.includes("What would you like to do next?")
}
```

**Hallucination loop detection:**

```typescript
interface SessionWatch {
    status: string
    continueCount: number
    lastContinueAt: number
}

const sessions = new Map<string, SessionWatch>()

function recordContinue(sid: string) {
    const w = sessions.get(sid) ?? { status: "unknown", continueCount: 0, lastContinueAt: 0 }
    const now = Date.now()
    
    // Reset if more than 10 minutes since last continue
    if (now - w.lastContinueAt > 600000) {
        w.continueCount = 0
    }
    
    w.continueCount++
    w.lastContinueAt = now
    sessions.set(sid, w)
}

function isLoopDetected(sid: string): boolean {
    const w = sessions.get(sid)
    return w !== undefined && w.continueCount >= 3
}
```

### References

- SDK types: `node_modules/@opencode-ai/sdk/dist/index.d.ts`
- OpenCode core: `https://github.com/anomalyco/opencode`
- Plugin source: `packages/opencode/src/plugin/`
