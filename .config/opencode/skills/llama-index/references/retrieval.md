# LlamaIndex - Retrieval Reference

> This reference is loaded on demand from ../SKILL.md for advanced retrieval topics.

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