---
name: llama-index
description: Comprehensive guide for building LLM applications with LlamaIndex, including data loaders, indexes, query engines, chat engines, vector stores, retrievers, agents, evaluation, streaming, and observability.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - llama-index
    - llm
    - rag
    - ai
    - python
    - vector-database
    - openai
    - agents
---

# LlamaIndex Development

Complete guide for building LLM applications with LlamaIndex framework.

## Overview

LlamaIndex is a data framework for LLM applications, providing tools for data ingestion, indexing, and retrieval.

**Key Characteristics:**
- RAG (Retrieval Augmented Generation) support
- Multiple data connectors (300+)
- Various index types
- Query and chat engines
- Vector store integrations
- Agent framework

## Installation

### Setup

```bash
# Basic installation
pip install llama-index

# With OpenAI
pip install llama-index-llms-openai
pip install llama-index-embeddings-openai

# With vector stores
pip install llama-index-vector-stores-chroma
pip install llama-index-vector-stores-pinecone
pip install llama-index-vector-stores-qdrant

# With evaluation
pip install llama-index-llms-openai ragas
```

### Basic Configuration

```python
import os
from llama_index.core import Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

# Set API key
os.environ["OPENAI_API_KEY"] = "your-api-key"

# Configure global settings
Settings.llm = OpenAI(model="gpt-4o", temperature=0.0)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")
Settings.chunk_size = 512
Settings.chunk_overlap = 50
```

## Quick Start

### Basic RAG Pipeline

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader

# Load documents
documents = SimpleDirectoryReader("./data").load_data()

# Create index
index = VectorStoreIndex.from_documents(documents)

# Create query engine
query_engine = index.as_query_engine()

# Query
response = query_engine.query("What is the main topic?")
print(response)
```

### With Storage

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, StorageContext
from llama_index.embeddings.openai import OpenAIEmbedding
import chromadb
from llama_index.vector_stores.chroma import ChromaVectorStore

# Setup ChromaDB
db = chromadb.PersistentClient(path="./chroma_db")
chroma_collection = db.get_or_create_collection("my_collection")
vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# Load and index
documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context,
    embed_model=OpenAIEmbedding(),
)

# Persist
storage_context.persist()

# Load from disk
index = VectorStoreIndex.from_vector_store(
    vector_store,
    embed_model=OpenAIEmbedding(),
)
```

## Data Loading

### Document Loaders

```python
from llama_index.core import SimpleDirectoryReader, Document

# Load from directory
documents = SimpleDirectoryReader(
    input_dir="./data",
    required_exts=[".pdf", ".txt", ".md"],
    exclude=["*.tmp"],
    recursive=True,
).load_data()

# Load specific files
documents = SimpleDirectoryReader(
    input_files=["./file1.pdf", "./file2.txt"]
).load_data()

# Create documents manually
documents = [
    Document(text="Content here", metadata={"source": "manual"}),
]

# With metadata extraction
def custom_metadata_func(file_path: str) -> dict:
    return {
        "file_path": file_path,
        "file_name": os.path.basename(file_path),
    }

documents = SimpleDirectoryReader(
    input_dir="./data",
    file_metadata=custom_metadata_func,
).load_data()
```

### Custom Data Connectors

```python
from llama_index.core import Document
from typing import List

class CustomDataReader:
    """Custom data loader."""

    def load_data(self, source: str) -> List[Document]:
        documents = []

        # Load from custom source
        # Example: API, database, etc.
        data = self._fetch_from_source(source)

        for item in data:
            doc = Document(
                text=item["content"],
                metadata={
                    "source": source,
                    "id": item["id"],
                    "timestamp": item["timestamp"],
                },
            )
            documents.append(doc)

        return documents

    def _fetch_from_source(self, source: str):
        # Implement data fetching
        pass

# Usage
reader = CustomDataReader()
documents = reader.load_data("api://endpoint")
```

## Node Parsing

### Chunking Strategies

```python
from llama_index.core.node_parser import (
    SentenceSplitter,
    TokenTextSplitter,
    SemanticSplitterNodeParser,
    HierarchicalNodeParser,
)
from llama_index.embeddings.openai import OpenAIEmbedding

# Sentence splitter (default)
splitter = SentenceSplitter(
    chunk_size=1024,
    chunk_overlap=20,
    paragraph_separator="\n\n",
)

nodes = splitter.get_nodes_from_documents(documents)

# Token splitter
token_splitter = TokenTextSplitter(
    chunk_size=512,
    chunk_overlap=50,
)

# Semantic splitter (uses embeddings)
semantic_splitter = SemanticSplitterNodeParser(
    buffer_size=1,
    breakpoint_percentile_threshold=95,
    embed_model=OpenAIEmbedding(),
)

# Hierarchical node parser
hierarchical_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128],  # Parent -> Child -> Grandchild
)
```

### Node Processing Pipeline

```python
from llama_index.core.ingestion import IngestionPipeline
from llama_index.core.extractors import (
    TitleExtractor,
    SummaryExtractor,
    KeywordExtractor,
)

# Create pipeline
pipeline = IngestionPipeline(
    transformations=[
        SentenceSplitter(chunk_size=1024, chunk_overlap=20),
        TitleExtractor(),
        SummaryExtractor(),
        KeywordExtractor(),
        OpenAIEmbedding(),
    ],
)

# Run pipeline
nodes = pipeline.run(documents=documents)

# Access metadata
for node in nodes[:3]:
    print(f"Title: {node.metadata.get('document_title')}")
    print(f"Summary: {node.metadata.get('section_summary')}")
    print(f"Keywords: {node.metadata.get('excerpt_keywords')}")
```

## Vector Stores

### ChromaDB

```python
import chromadb
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import VectorStoreIndex, StorageContext

# Persistent client
db = chromadb.PersistentClient(path="./chroma_db")
chroma_collection = db.get_or_create_collection("my_collection")

# Create vector store
vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# Create index
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context,
)

# Load existing
index = VectorStoreIndex.from_vector_store(vector_store)
```

### Pinecone

```python
import pinecone
from llama_index.vector_stores.pinecone import PineconeVectorStore
from llama_index.core import VectorStoreIndex, StorageContext

# Initialize Pinecone
pinecone.init(
    api_key=os.environ["PINECONE_API_KEY"],
    environment=os.environ["PINECONE_ENV"],
)

# Create index if not exists
if "my_index" not in pinecone.list_indexes():
    pinecone.create_index(
        "my_index",
        dimension=1536,
        metric="cosine",
    )

pinecone_index = pinecone.Index("my_index")
vector_store = PineconeVectorStore(pinecone_index=pinecone_index)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# Create index
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context,
)
```

### Qdrant

```python
from qdrant_client import QdrantClient
from llama_index.vector_stores.qdrant import QdrantVectorStore
from llama_index.core import VectorStoreIndex, StorageContext

# Initialize client
client = QdrantClient(host="localhost", port=6333)

# Create vector store
vector_store = QdrantVectorStore(
    collection_name="my_collection",
    client=client,
)

storage_context = StorageContext.from_defaults(vector_store=vector_store)
index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context,
)
```

## Advanced Retrievers

### Hybrid Search

```python
from llama_index.core import VectorStoreIndex, SimpleKeywordTableIndex
from llama_index.core.retrievers import VectorIndexRetriever, KeywordTableSimpleRetriever
from llama_index.core.schema import QueryBundle

class HybridRetriever:
    """Combine vector and keyword search."""

    def __init__(self, vector_index, keyword_index, mode="OR"):
        self.vector_retriever = VectorIndexRetriever(
            index=vector_index,
            similarity_top_k=10,
        )
        self.keyword_retriever = KeywordTableSimpleRetriever(
            index=keyword_index,
            similarity_top_k=10,
        )
        self.mode = mode

    def retrieve(self, query: str):
        query_bundle = QueryBundle(query_str=query)

        vector_nodes = self.vector_retriever.retrieve(query_bundle)
        keyword_nodes = self.keyword_retriever.retrieve(query_bundle)

        vector_ids = {n.node.node_id for n in vector_nodes}
        keyword_ids = {n.node.node_id for n in keyword_nodes}

        if self.mode == "AND":
            combined_ids = vector_ids.intersection(keyword_ids)
        else:
            combined_ids = vector_ids.union(keyword_ids)

        combined_dict = {n.node.node_id: n for n in vector_nodes}
        combined_dict.update({n.node.node_id: n for n in keyword_nodes})

        return [combined_dict[nid] for nid in combined_ids]

# Usage
vector_index = VectorStoreIndex.from_documents(documents)
keyword_index = SimpleKeywordTableIndex.from_documents(documents)

hybrid_retriever = HybridRetriever(vector_index, keyword_index)
nodes = hybrid_retriever.retrieve("search query")
```

### Query Fusion Retriever

```python
from llama_index.core.retrievers import QueryFusionRetriever, VectorIndexRetriever
from llama_index.core.postprocessor import SentenceTransformerRerank

# Create retrievers
vector_retriever = VectorIndexRetriever(
    index=vector_index,
    similarity_top_k=20,
)

# Fusion retriever with query expansion
fusion_retriever = QueryFusionRetriever(
    retrievers=[vector_retriever],
    similarity_top_k=10,
    num_queries=3,  # Generate 3 query variations
    mode="reciprocal_rerank",
    use_async=True,
)

# Add reranker
reranker = SentenceTransformerRerank(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2",
    top_n=5,
)

# Use in query engine
query_engine = RetrieverQueryEngine(
    retriever=fusion_retriever,
    node_postprocessors=[reranker],
)
```

### Auto-Merging Retriever

```python
from llama_index.core.node_parser import HierarchicalNodeParser
from llama_index.core.retrievers import AutoMergingRetriever
from llama_index.core.storage import StorageContext

# Create hierarchical nodes
node_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128],
)

nodes = node_parser.get_nodes_from_documents(documents)
storage_context = StorageContext.from_defaults(nodes=nodes)

# Create index
index = VectorStoreIndex(nodes, storage_context=storage_context)

# Create auto-merging retriever
auto_merging_retriever = AutoMergingRetriever(
    index.as_retriever(similarity_top_k=6),
    storage_context=storage_context,
    verbose=True,
)

# Use
query_engine = RetrieverQueryEngine(retriever=auto_merging_retriever)
```

## Rerankers

### SentenceTransformer Reranker

```python
from llama_index.core.postprocessor import SentenceTransformerRerank
from llama_index.core import VectorStoreIndex

# Create reranker
reranker = SentenceTransformerRerank(
    model="cross-encoder/ms-marco-MiniLM-L-6-v2",
    top_n=5,
)

# Use in query engine
query_engine = index.as_query_engine(
    similarity_top_k=20,  # Retrieve more
    node_postprocessors=[reranker],  # Then rerank
)

response = query_engine.query("Your query")
```

### Cohere Reranker

```python
from llama_index.core.postprocessor import CohereRerank

reranker = CohereRerank(
    api_key=os.environ["COHERE_API_KEY"],
    top_n=5,
    model="rerank-english-v3.0",
)

query_engine = index.as_query_engine(
    similarity_top_k=20,
    node_postprocessors=[reranker],
)
```

### LLM Reranker

```python
from llama_index.core.postprocessor import LLMRerank
from llama_index.llms.openai import OpenAI

reranker = LLMRerank(
    top_n=5,
    llm=OpenAI(model="gpt-4o", temperature=0.0),
)

query_engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[reranker],
)
```

## Query Engines

### Router Query Engine

```python
from llama_index.core.query_engine import RouterQueryEngine
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.core.selectors import LLMSingleSelector

# Create multiple query engines
summary_engine = summary_index.as_query_engine()
vector_engine = vector_index.as_query_engine()

# Create tools
query_engine_tools = [
    QueryEngineTool(
        query_engine=summary_engine,
        metadata=ToolMetadata(
            name="summary_tool",
            description="Useful for summarizing documents",
        ),
    ),
    QueryEngineTool(
        query_engine=vector_engine,
        metadata=ToolMetadata(
            name="vector_tool",
            description="Useful for specific questions about documents",
        ),
    ),
]

# Create router
router_engine = RouterQueryEngine(
    selector=LLMSingleSelector.from_defaults(),
    query_engine_tools=query_engine_tools,
    verbose=True,
)

response = router_engine.query("What is the main topic?")
```

### Sub-Question Query Engine

```python
from llama_index.core.query_engine import SubQuestionQueryEngine

# Create sub-question engine
sub_question_engine = SubQuestionQueryEngine.from_defaults(
    query_engine_tools=query_engine_tools,
    use_async=True,
    verbose=True,
)

# Automatically decomposes into sub-questions
response = sub_question_engine.query(
    "Compare the revenue growth of Company A and Company B"
)
```

### Multi-Step Query Engine

```python
from llama_index.core.query_engine import MultiStepQueryEngine

# Create multi-step engine
multi_step_engine = MultiStepQueryEngine(
    query_engine=base_query_engine,
    llm=OpenAI(model="gpt-4o"),
    max_iterations=5,
    verbose=True,
)

# Breaks down complex questions
response = multi_step_engine.query(
    "What factors contributed to the market cap change?"
)
```

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

## Evaluation

### Faithfulness Evaluation

```python
from llama_index.core.evaluation import FaithfulnessEvaluator
from llama_index.llms.openai import OpenAI

# Create evaluator
llm = OpenAI(model="gpt-4o", temperature=0.0)
evaluator = FaithfulnessEvaluator(llm=llm)

# Evaluate response
query_engine = index.as_query_engine()
response = query_engine.query("What are the key points?")

eval_result = evaluator.evaluate_response(response=response)

print(f"Passing: {eval_result.passing}")
print(f"Feedback: {eval_result.feedback}")
```

### Relevancy Evaluation

```python
from llama_index.core.evaluation import RelevancyEvaluator

evaluator = RelevancyEvaluator(llm=llm)

eval_result = evaluator.evaluate_response(
    query="What is the main topic?",
    response=response,
)

print(f"Passing: {eval_result.passing}")
print(f"Score: {eval_result.score}")
```

### Ragas Integration

```python
from llama_index.core.evaluation import RagasEvaluator
from llama_index.core.evaluation.ragas import RagasMetric

# Create evaluator
evaluator = RagasEvaluator(
    metric=RagasMetric.FAITHFULNESS,
)

# Evaluate
result = evaluator.evaluate_response(
    query=query,
    response=response,
    contexts=[node.text for node in response.source_nodes],
)

print(f"Score: {result.score}")
```

### Batch Evaluation

```python
from tqdm import tqdm

def batch_evaluate(queries, responses, evaluator):
    results = []

    for query, response in tqdm(zip(queries, responses)):
        result = evaluator.evaluate_response(
            query=query,
            response=response,
        )
        results.append(result)

    passing_rate = sum(1 for r in results if r.passing) / len(results)
    avg_score = sum(r.score for r in results if r.score) / len(results)

    return {
        "passing_rate": passing_rate,
        "average_score": avg_score,
        "results": results,
    }
```

## Observability

### Callbacks and Token Tracking

```python
from llama_index.core import Settings
from llama_index.core.callbacks import (
    CallbackManager,
    LlamaDebugHandler,
    TokenCountingHandler,
)
import tiktoken

# Create handlers
token_counter = TokenCountingHandler(
    tokenizer=tiktoken.encoding_for_model("gpt-4o").encode,
)
debug_handler = LlamaDebugHandler(print_trace_on_end=True)

# Set callback manager
Settings.callback_manager = CallbackManager([token_counter, debug_handler])

# Run query
response = query_engine.query("Your query")

# Get token counts
print(f"Total LLM tokens: {token_counter.total_llm_token_count}")
print(f"Embedding tokens: {token_counter.total_embedding_token_count}")
```

### LlamaIndex Debugging

```python
from llama_index.core.callbacks import LlamaDebugHandler

debug_handler = LlamaDebugHandler()
Settings.callback_manager = CallbackManager([debug_handler])

# Run query
response = query_engine.query("Your query")

# Get events
events = debug_handler.get_event_pairs()

for event in events:
    print(f"Event: {event[0].type}")
    print(f"Duration: {event[1].time - event[0].time}")
```

### LangSmith Integration

```python
import os

os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "your-langsmith-key"
os.environ["LANGCHAIN_PROJECT"] = "my-project"

# LlamaIndex automatically logs to LangSmith
response = query_engine.query("Your query")
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

## Common Issues

### Chunk Size Problems

```python
# ❌ BAD: Too small chunks lose context
splitter = SentenceSplitter(chunk_size=64)

# ❌ BAD: Too large chunks dilute relevance
splitter = SentenceSplitter(chunk_size=8192)

# ✅ GOOD: Balanced chunk size
splitter = SentenceSplitter(
    chunk_size=512,  # For embeddings
    chunk_overlap=50,  # ~10% overlap
)
```

### Retrieval Quality

```python
# ❌ BAD: No reranking, few results
query_engine = index.as_query_engine(similarity_top_k=3)

# ✅ GOOD: Retrieve more, rerank
query_engine = index.as_query_engine(
    similarity_top_k=20,
    node_postprocessors=[
        SentenceTransformerRerank(top_n=5),
    ],
)
```

### Memory Issues

```python
# ❌ BAD: Load all documents at once
documents = SimpleDirectoryReader("./huge_folder").load_data()

# ✅ GOOD: Process in batches
from llama_index.core import StorageContext

for batch in document_batches:
    nodes = splitter.get_nodes_from_documents(batch)
    index.insert_nodes(nodes)
```

### Embedding Dimension Mismatch

```python
# ❌ BAD: Index created with different embedding
# Pinecone index: 1536 dimensions
# Using: 768 dimension embeddings

# ✅ GOOD: Match dimensions
embed_model = OpenAIEmbedding(model="text-embedding-3-small")  # 1536 dims
# Create Pinecone index with same dimensions
```

## Best Practices

1. **Use appropriate chunk sizes** (512-1024 for most use cases)
2. **Always add overlap** (5-10% of chunk size)
3. **Use rerankers** for better retrieval quality
4. **Enable streaming** for better UX
5. **Use async** for parallel queries
6. **Implement caching** for repeated queries
7. **Monitor token usage** with callbacks
8. **Test with evaluation** before production
9. **Use hybrid search** for better recall
10. **Keep context window** in mind for chat

## Resources

- **Documentation:** https://docs.llamaindex.ai/
- **GitHub:** https://github.com/run-llama/llama_index
- **Examples:** https://github.com/run-llama/llama_index/tree/main/docs/examples
- **Discord:** https://discord.gg/dGcwcsnxhU
- **Blog:** https://blog.llamaindex.ai/

## Quick Reference

### Common Imports

```python
from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Document,
    Settings,
    StorageContext,
)
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.retrievers import VectorIndexRetriever
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding
```

### Common Patterns

```python
# Basic RAG
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine()
response = query_engine.query("query")

# With reranking
query_engine = index.as_query_engine(
    similarity_top_k=20,
    node_postprocessors=[reranker],
)

# Streaming
query_engine = index.as_query_engine(streaming=True)
for token in query_engine.query("query").response_gen:
    print(token)

# Chat
chat_engine = index.as_chat_engine()
response = chat_engine.chat("message")

# Agent
agent = ReActAgent.from_tools(tools, llm=llm)
response = agent.chat("message")
```
