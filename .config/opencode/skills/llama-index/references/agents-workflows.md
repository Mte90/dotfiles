# LlamaIndex - Agents & Workflows Reference

> This reference is loaded on demand from ../SKILL.md for agents, streaming, workflows, and chat engines.

## Agents

### ReAct Agent

```python
from llama_index.core.agent import ReActAgent
from llama_index.core.tools import FunctionTool
from llama_index.llms.openai import OpenAI

# Define tools
def add(x: int, y: int) -> int:
    """Add two numbers."""
    return x + y

def multiply(x: int, y: int) -> int:
    """Multiply two numbers."""
    return x * y

def search_knowledge(query: str) -> str:
    """Search the knowledge base."""
    response = query_engine.query(query)
    return str(response)

tools = [
    FunctionTool.from_defaults(add),
    FunctionTool.from_defaults(multiply),
    FunctionTool.from_defaults(search_knowledge),
]

# Create agent
agent = ReActAgent(
    llm=OpenAI(model="gpt-4o", temperature=0.0),
    tools=tools,
    max_iterations=10,
    verbose=True,
)

# Run
response = agent.chat("What is 20 + (5 * 3)?")
print(response)
```

### Function Calling Agent

```python
from llama_index.core.agent import FunctionCallingAgent

# Use for models with native function calling
agent = FunctionCallingAgent(
    llm=OpenAI(model="gpt-4o"),
    tools=tools,
    max_iterations=10,
    verbose=True,
)

response = agent.chat("Calculate and search")
```

### Custom Tools

```python
from llama_index.core.tools import BaseTool
from pydantic import BaseModel, Field
from typing import Optional

# Pydantic input schema
class SearchInput(BaseModel):
    query: str = Field(description="Search query")
    limit: Optional[int] = Field(default=10, description="Max results")
    category: Optional[str] = Field(default=None, description="Filter category")

class CustomSearchTool(BaseTool):
    name = "custom_search"
    description = "Search with structured parameters"

    def __call__(self, input: SearchInput) -> str:
        results = self._search(input.query, input.limit, input.category)
        return "\n".join(results)

    def _search(self, query: str, limit: int, category: str):
        # Implementation
        return ["result1", "result2"]

# Usage
tool = CustomSearchTool()
agent = ReActAgent(llm=llm, tools=[tool])
```

### Query Engine as Tool

```python
from llama_index.core.tools import QueryEngineTool, ToolMetadata

# Wrap query engine as tool
query_tool = QueryEngineTool(
    query_engine=index.as_query_engine(),
    metadata=ToolMetadata(
        name="knowledge_base",
        description="Search the knowledge base for information",
    ),
)

# Use in agent
agent = ReActAgent(
    llm=OpenAI(model="gpt-4o"),
    tools=[query_tool, other_tool],
)
```

## Streaming

### Streaming Responses

```python
from llama_index.core import VectorStoreIndex

# Enable streaming
query_engine = index.as_query_engine(streaming=True)

# Stream response
response = query_engine.query("What is the main topic?")

# Print tokens as they arrive
for token in response.response_gen:
    print(token, end="", flush=True)
```

### Async Streaming

```python
import asyncio

async def stream_query(query: str):
    streaming_response = await query_engine.aquery(query)

    content = ""
    async for token in streaming_response.async_response_gen():
        print(token, end="", flush=True)
        content += token

    return content

# Run
asyncio.run(stream_query("Your query"))
```

### Streaming Chat

```python
from llama_index.core.memory import ChatMemoryBuffer

# Create chat engine with memory
memory = ChatMemoryBuffer.from_defaults(token_limit=1500)
chat_engine = index.as_chat_engine(
    chat_mode="context",
    memory=memory,
    streaming=True,
)

# Stream chat
response = chat_engine.stream_chat("Tell me about topic X")
for token in response.response_gen:
    print(token, end="", flush=True)

# Continue conversation
response = chat_engine.stream_chat("Can you elaborate?")
for token in response.response_gen:
    print(token, end="", flush=True)
```

### FastAPI Streaming

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.post("/stream")
async def stream_response(query: str):
    async def generate():
        streaming_response = await query_engine.aquery(query)
        async for token in streaming_response.async_response_gen():
            yield f"data: {token}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
    )
```

## Workflow Engine (v0.14+)

The workflow engine provides a structured way to build complex, multi-step LLM applications.

```python
from llama_index.core.workflow import Workflow, step, Event, StartEvent, StopEvent
from typing import Context

class QueryEvent(StartEvent):
    """Input event for queries."""
    query: str

class ResponseEvent(StopEvent):
    """Output event with final response."""
    response: str

class SimpleSearchWorkflow(Workflow):
    """Simple workflow for search + response."""
    
    @step
    async def search_step(self, ctx: Context, ev: QueryEvent) -> dict:
        """First step: search knowledge base."""
        query = ev.query
        # Perform search
        results = await self._search(query)
        ctx.set("search_results", results)
        return {"results": results}
    
    @step
    async def response_step(self, ctx: Context, ev: dict) -> ResponseEvent:
        """Second step: generate response."""
        results = ctx.get("search_results")
        response = await self._generate_response(results)
        return ResponseEvent(response=response)
    
    async def _search(self, query: str) -> list:
        # Implementation
        return []
    
    async def _generate_response(self, results: list) -> str:
        # Implementation
        return ""

# Usage
workflow = SimpleSearchWorkflow(timeout=30)
result = await workflow.run(query="What is X?")
print(result.response)
```

### Workflow Patterns

```python
# Parallel steps
@step
async def parallel_fetch(self, ctx: Context, ev: StartEvent) -> dict:
    """Fetch data from multiple sources in parallel."""
    results = await asyncio.gather(
        self._fetch_source_a(),
        self._fetch_source_b(),
        self._fetch_source_c(),
    )
    return {"sources": results}

# Conditional branching
@step
async def route_step(self, ctx: Context, ev: dict) -> str:
    """Route based on data."""
    if ev.get("needs_enrichment"):
        return "enrichment_step"
    return "direct_response"

# Retry logic
@step(retries=3)
async def resilient_step(self, ctx: Context, ev: Event) -> dict:
    """Step with automatic retries."""
    return await self._resilient_operation()
```

## Chat Engines

### Basic Chat

```python
from llama_index.core import VectorStoreIndex

# Create chat engine
chat_engine = index.as_chat_engine(
    chat_mode="condense_question",
    verbose=True,
)

# Chat
response = chat_engine.chat("Tell me about X")
print(response)

response = chat_engine.chat("Can you elaborate?")
print(response)
```

### Chat with Memory

```python
from llama_index.core.memory import ChatMemoryBuffer

# Create memory
memory = ChatMemoryBuffer.from_defaults(token_limit=2000)

chat_engine = index.as_chat_engine(
    chat_mode="context",
    memory=memory,
    system_prompt="You are a helpful assistant.",
    verbose=True,
)

# Chat maintains context
response = chat_engine.chat("What is X?")
response = chat_engine.chat("Give me more details")

# Reset memory
chat_engine.reset()
```

### Chat Modes

```python
# condense_question - Condenses chat history + question
chat_engine = index.as_chat_engine(chat_mode="condense_question")

# context - Uses context from index
chat_engine = index.as_chat_engine(chat_mode="context")

# condense_plus_context - Both condense and context
chat_engine = index.as_chat_engine(chat_mode="condense_plus_context")

# react - ReAct agent mode
chat_engine = index.as_chat_engine(chat_mode="react", verbose=True)

# openai - OpenAI function calling
chat_engine = index.as_chat_engine(chat_mode="openai")
```