---
name: pydantic
description: Use when validating and serializing Python data with Pydantic v2 - models, field and model validators, constrained and special types, TypeAdapter, discriminated unions, BaseSettings, or FastAPI integration
metadata:
  author: mte90
  version: 2.0.0
  tags:
    - python
    - validation
    - pydantic
    - serialization
    - settings
---

# Pydantic

Data validation using Python type annotations.

## Overview

Pydantic provides data validation and settings management using Python type hints. Validates at runtime and generates JSON Schema.

**Source**: https://docs.pydantic.dev/ | https://github.com/pydantic/pydantic

## Installation

```bash
pip install pydantic          # Core
pip install pydantic[email]   # Email validation
pip install pydantic orjson   # Best performance
pip install pydantic-settings # Settings management
```

## Quick Start

```python
from pydantic import BaseModel, Field

class User(BaseModel):
    id: int
    name: str
    email: str
    age: int | None = None

# Validation + coercion
user = User(id="1", name="John", email="john@example.com")  # id coerced to int

# From dict/JSON
user = User.model_validate({"id": 2, "name": "Jane", "email": "jane@example.com"})
user = User.model_validate_json('{"id": 3, "name": "Bob", "email": "bob@example.com"}')

# Serialization
data = user.model_dump()           # dict
json_str = user.model_dump_json()  # JSON string
```

## Field Constraints

Compact examples—see [validators.md](references/validators.md) for full reference.

```python
from pydantic import BaseModel, Field
from typing import Optional, List

class ConstrainedModel(BaseModel):
    # Strings
    name: str = Field(min_length=1, max_length=100)
    username: str = Field(pattern=r'^[a-zA-Z0-9_]+$')
    
    # Numbers
    age: int = Field(ge=0, le=150)
    price: float = Field(gt=0)
    
    # Collections
    tags: List[str] = Field(min_length=1)
    
    # Optional
    nickname: Optional[str] = Field(default=None, max_length=50)
```

## Validators

See [validators.md](references/validators.md) for comprehensive patterns.

```python
from pydantic import BaseModel, field_validator, model_validator, Field
import re

class ValidatedModel(BaseModel):
    username: str
    password: str
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        return v.strip().lower()
    
    @model_validator(mode='after')
    def validate_password_strength(self):
        if len(self.password) < 8:
            raise ValueError('Password too short')
        if not re.search(r'[A-Z]', self.password):
            raise ValueError('Password needs uppercase')
        return self
```

## v1 → v2 Migration Checklist

Critical: v2 changes can silently break v1 code. Check each item.

| v1 | v2 | Symptom |
|----|----|---------|
| `@validator` | `@field_validator` | Import error; `validator` deprecated |
| `@validator(..., each_item=True)` | `@field_validator` with `PlainSerializer` | List validation fails |
| `@root_validator` | `@model_validator(mode='before'/'after')` | `root_validator` removed; need mode |
| `class Config` | `model_config = ConfigDict(...)` | `Config` class ignored |
| `.dict()` | `.model_dump()` | Method not found |
| `.json()` | `.model_dump_json()` | Method not found |
| `.parse_obj()` | `.model_validate()` | Method not found |
| `.parse_raw()` | `.model_validate_json()` | Method not found |
| `.schema()` | `.model_json_schema()` | Method not found |
| `Field(..., regex=r'...')` | `Field(pattern=r'...')` | `regex` removed |
| `Field(..., min_length=...)` | `Field(min_length=...)` | Works (unchanged) |
| `copy(update={...})` | `model_copy(update={...})` | `copy` is shallow; use `model_copy` |
| `allow_population_by_field_name` | `populate_by_name` | Config key renamed |
| `orm_mode` | `from_attributes` | Config key renamed |
| `Optional[X] = None` default behavior | Defaults no longer filled for `None` | `None` stays `None`, not replaced |

**Source**: https://docs.pydantic.dev/latest/migration/

## Serialization Performance

Measure before optimizing: use `timeit` or a profiler on `model_dump()` for deeply nested models.

```python
from pydantic import BaseModel
from typing import Optional, List
import time

class NestedModel(BaseModel):
    data: dict
    items: List[str]

class DeepModel(BaseModel):
    level1: NestedModel
    level2: NestedModel
    level3: NestedModel

model = DeepModel(
    level1=NestedModel(data={}, items=[]),
    level2=NestedModel(data={}, items=[]),
    level3=NestedModel(data={}, items=[])
)

# Measure
start = time.perf_counter()
for _ in range(10000):
    model.model_dump()
print(f"Time: {time.perf_counter() - start:.3f}s")
```

**Guidance**:

- **`model_dump()` vs `dict(model)`**: `model_dump()` is O(1) per field; `dict(model)` triggers reflection O(fields) each call. Always use `model_dump()`.
- **`model_dump(mode="json")`**: Use when the consumer is JSON (serializes datetime, decimals, etc. to JSON-native types).
- **`exclude_none=True`**: Omits fields with `None` value. Use when you want to hide nulls.
- **`exclude_unset=True`**: Omits fields that were never explicitly set (even if they have defaults). Usually what you want for partial updates.
- **Deeply nested models**: The hot spot. Profile first; consider selective `include`/`exclude` or flattening.

## Django Integration

See [django.md](references/django.md) for detailed patterns.

```python
from pydantic import BaseModel, ConfigDict
from myapp.models import User as UserModel

class UserPydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    username: str
    email: str

# Accept ORM objects
user_orm = UserModel.objects.get(id=1)
user_py = UserPydantic.model_validate(user_orm)  # from_attributes=True enables this

# DjangoChoices for enum validation
from django.db import models

class Status(models.TextChoices):
    PENDING = "pending"
    ACTIVE = "active"

# Must be TextChoices, not plain str for enum validation
from pydantic import BaseModel

class Task(BaseModel):
    status: Status  # Works with TextChoices
```

**Pitfalls**:

- **Unsaved instances**: Validating an unsaved Django model instance may fail if validators expect `id` or other DB-generated fields.
- **Lazy model fields**: Use `DjangoGetter` wrapper for lazy evaluation of related fields (avoids N+1 queries).

## When Not to Use a Strict Model

Not every case benefits from Pydantic's coercion:

- **Internal dataclasses**: Where data is already validated at the boundary, coercion surprises hurt more than help. Use `@dataclass` or plain classes internally.
- **Boundary discipline**: Validate external input ONCE at the boundary. Internal call sites should not re-validate—pass typed data directly.
- **Performance-critical paths**: If validation is not needed (e.g., internal cache hits), skip Pydantic overhead.

```python
# Good: Validate at boundary
def handle_request(raw_data: dict):
    user = User.model_validate(raw_data)  # Boundary
    process_user(user)  # Internal—no re-validation

def process_user(user: User):
    # Use user directly; trust the type
    send_email(user.email)

# Bad: Re-validating internally
def process_user_bad(raw_data: dict):
    user = User.model_validate(raw_data)
    # ...
    user_again = User.model_validate(user.model_dump())  # Unnecessary
```

## Best Practices

1. **Use `Field(default_factory=...)` for mutable defaults**
   ```python
   class Model(BaseModel):
       tags: List[str] = Field(default_factory=list)  # Good
       # tags: List[str] = []  # Bad in v2
   ```

2. **Separate schemas for operations**
   ```python
   class UserBase(BaseModel):
       email: str

   class UserCreate(UserBase):
       username: str
       password: str

   class UserResponse(UserBase):
       id: int
       model_config = ConfigDict(from_attributes=True)
   ```

3. **Validate once at the boundary** (see above)

## Common Issues

### Mutable Defaults

```python
# v2 error: mutable default
class BadModel(BaseModel):
    items: list = []

# Fix: use default_factory
class GoodModel(BaseModel):
    items: list = Field(default_factory=list)
```

### Performance

- Use Pydantic v2 (parsing is 10-100x faster than v1)
- Use `orjson` for serialization: `model_config = ConfigDict(json_loads=orjson.loads, json_dumps=orjson.dumps)`
- Measure `model_dump()` on deeply nested models first

## Deep Dives

Load these reference files on demand:

- **validators.md** — Field/model validators, custom types, error handling, TypeAdapter, discriminated unions
- **types-and-defaults.md** — Field aliases, naming conventions, constrained types, special types (email, URL, UUID, secrets, enums)
- **config-and-settings.md** — Model configuration, strict mode, multi-environment settings, BaseSettings
- **django.md** — Django ORM integration, DjangoGetter, TextChoices, unsaved instance pitfalls
- **fastapi.md** — FastAPI integration with request/response models and nested validation

## References

- Official Docs: https://docs.pydantic.dev/
- GitHub: https://github.com/pydantic/pydantic
- Pydantic Discord: https://discord.gg/pydantic
- FastAPI: https://fastapi.tiangolo.com/
