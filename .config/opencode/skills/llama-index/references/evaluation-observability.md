# LlamaIndex - Evaluation & Observability Reference

> This reference is loaded on demand from ../SKILL.md for evaluation and observability topics.

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