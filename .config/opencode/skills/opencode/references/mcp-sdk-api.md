<!-- Loaded on demand from ../SKILL.md -->

# MCP Integration, SDK Usage & HTTP API

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

---

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

---

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