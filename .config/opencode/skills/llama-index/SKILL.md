---
name: llama-index
description: Use when building RAG or LLM applications with LlamaIndex - data loaders, node parsing, vector stores, retrievers and rerankers, query engines, agents and workflows, streaming, or evaluation
metadata:
  author: mte90
  version: 2.0.0
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
# Basic installation (v0.14+)
pip install llama-index

# With OpenAI
pip install llama-index-llms-openai
pip install llama-index-embeddings-openai

# With workflow engine support
pip install llama-index-core

# With vector stores
pip install llama-index-vector-stores-chroma
pip install llama-index-vector-stores-pinecone
pip install llama-index-vector-stores-qdrant

# With evaluation
pip install llama-index-llms-openai ragas
```

### Version Notes

- Current stable: v0.14.x (rapid monthly releases)
- Import paths unified under `llama_index.core`
- Workflow engine added for complex multi-step operations

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

### Basic RAG Pipeline (v0.14+)

```python
# Unified imports in v0.14+
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, StorageContext, load_index_from_storage

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

## Deep Dives

Advanced topics are split into reference files loaded on demand:

- **retrieval.md** — Advanced retrievers (hybrid, query fusion, auto-merging), rerankers, query engines (router, sub-question, multi-step)
- **agents-workflows.md** — Agents (ReAct, function calling, custom tools), streaming, workflow engine, chat engines
- **evaluation-observability.md** — Evaluation (faithfulness, relevancy, ragas), observability (callbacks, LangSmith)

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