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

Pydantic is a Python library that provides data validation and settings management using Python type annotations. It validates data at runtime and generates JSON Schema for automatic documentation.

**Key Features:**
- Data validation using type hints
- Automatic data coercion
- JSON Schema generation
- Serialization/deserialization
- Settings management with environment variables
- Fast performance (especially v2)
- Extensive customization options

### Installation

```bash
# Basic installation
pip install pydantic

# With email validation
pip install pydantic[email]

# With best performance (recommended)
pip install pydantic[email] orjson

# Version 2 (current)
pip install pydantic>=2.0.0
```

## Basic Models

### Creating Models

```python
from pydantic import BaseModel, Field
from typing import Optional, List

class User(BaseModel):
    """Basic user model."""
    id: int
    name: str
    email: str
    age: Optional[int] = None
    is_active: bool = True

# Create instance
user = User(id=1, name="John", email="john@example.com")
print(user)
# id=1 name='John' email='john@example.com' age=None is_active=True

# From dictionary
data = {
    "id": 2,
    "name": "Jane",
    "email": "jane@example.com",
    "age": 25
}
user = User(**data)

# From JSON
json_data = '{"id": 3, "name": "Bob", "email": "bob@example.com"}'
user = User.model_validate_json(json_data)
```

### Field Types

```python
from pydantic import BaseModel
from typing import Optional, List, Dict, Literal

class AllTypesExample(BaseModel):
    string: str
    integer: int
    optional_string: Optional[str] = None
    list_of_strings: List[str] = []
    dict_data: Dict[str, int] = {}
    status: Literal["pending", "active"] = "pending"
```

### Nested Models

```python
from pydantic import BaseModel, Field
from typing import Optional

class Address(BaseModel):
    street: str
    city: str

class Person(BaseModel):
    name: str
    email: str
    address: Optional[Address] = None

person = Person(
    name="John",
    email="john@example.com",
    address=Address(street="123 Main St", city="New York")
)
```

## Field Validation

### Field Constraints

```python
from pydantic import BaseModel, Field, field_validator
from typing import Optional
import re

class ConstrainedUser(BaseModel):
    # String constraints
    name: str = Field(min_length=1, max_length=100)
    username: str = Field(pattern=r'^[a-zA-Z0-9_]+$')
    email: str = Field(format="email")
    
    # Number constraints
    age: int = Field(ge=0, le=150)
    price: float = Field(gt=0)
    quantity: int = Field(ge=0, default=0)
    
    # Collection constraints
    tags: List[str] = Field(min_length=1, max_length=10)
    scores: List[int] = Field(min_length=1, max_length=100)
    
    # Optional with constraint
    nickname: Optional[str] = Field(default=None, max_length=50)

# Validation examples
user = ConstrainedUser(
    name="John Doe",
    username="john_doe",
    email="john@example.com",
    age=25,
    price=19.99,
    tags=["python", "fastapi"]
)
```

### Field Validators

```python
from pydantic import BaseModel, field_validator, Field
import re

class ValidatedUser(BaseModel):
    username: str
    password: str
    age: int
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username can only contain letters, numbers, and underscores')
        return v
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[0-9]', v):
            raise ValueError('Password must contain at least one digit')
        return v
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 0 or v > 150:
            raise ValueError('Age must be between 0 and 150')
        return v

# Multiple validators on same field
class MultiValidatedField(BaseModel):
    value: str
    
    @field_validator('value')
    @classmethod
    def strip_value(cls, v: str) -> str:
        return v.strip()
    
    @field_validator('value')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        if not v:
            raise ValueError('Value cannot be empty')
        return v
```

### Model Validators

```python
from pydantic import BaseModel, model_validator, field_validator
from typing import Optional

class UserRegistration(BaseModel):
    password: str
    confirm_password: str
    username: str
    
    @model_validator(mode='before')
    @classmethod
    def check_passwords_match(cls, data):
        """Validate before any field validation."""
        if isinstance(data, dict):
            if data.get('password') != data.get('confirm_password'):
                raise ValueError('Passwords do not match')
        return data
    
    @model_validator(mode='after')
    def validate_username_not_password(self):
        """Validate after all field validation."""
        if self.username.lower() in self.password.lower():
            raise ValueError('Username cannot be part of the password')
        return self

# Date validation
class AdvancedValidation(BaseModel):
    start_date: str
    end_date: str
    
    @model_validator(mode='after')
    def validate_dates(self):
        from datetime import datetime
        start = datetime.fromisoformat(self.start_date)
        end = datetime.fromisoformat(self.end_date)
        
        if end < start:
            raise ValueError('End date must be after start date')
        
        return self
```

## Serialization

### Model Dump

```python
from pydantic import BaseModel
from typing import List, Optional

class User(BaseModel):
    id: int
    name: str
    email: str
    tags: List[str] = []
    metadata: Optional[dict] = None

user = User(
    id=1,
    name="John",
    email="john@example.com",
    tags=["admin", "developer"],
    metadata={"department": "Engineering"}
)

# To dictionary
data = user.model_dump()
print(data)
# {'id': 1, 'name': 'John', 'email': 'john@example.com', 'tags': ['admin', 'developer'], 'metadata': {'department': 'Engineering'}}

# To JSON string
json_str = user.model_dump_json()
print(json_str)
# {"id":1,"name":"John",...}

# Include/Exclude fields
data = user.model_dump(include={'id', 'name'})
data = user.model_dump(exclude={'metadata'})

# Exclude None values
data = user.model_dump(exclude_none=True)
```

### Custom Serialization

```python
from pydantic import BaseModel, field_serializer
from datetime import datetime

class User(BaseModel):
    id: int
    created_at: datetime
    
    @field_serializer('created_at')
    def serialize_datetime(self, dt: datetime) -> str:
        return dt.isoformat()

user = User(id=1, created_at=datetime.now())
data = user.model_dump(mode='json', exclude_none=True)
```

### Model Validate

```python
from pydantic import BaseModel

class User(BaseModel):
    id: int
    name: str

# From dictionary
user = User.model_validate({"id": 1, "name": "John"})

# From JSON
user = User.model_validate_json('{"id": 2, "name": "Jane"}')
```

### JSON Schema

```python
from pydantic import BaseModel

class User(BaseModel):
    id: int
    name: str

schema = User.model_json_schema()
```

## Deep Dives

The following reference files provide detailed coverage of advanced topics. Load them on demand:

- **types-and-defaults.md** — Field aliases, naming conventions, default values, constrained types, and special types (email, URL, UUID, secrets, enums)
- **config-and-settings.md** — Model configuration, strict mode, multi-environment settings, and BaseSettings
- **validation-patterns.md** — TypeAdapter, RootModel, discriminated unions, and error handling
- **fastapi.md** — FastAPI integration with request/response models and nested validation

## Best Practices

### 1. Use Type Hints

```python
# Good: Full type hints
class User(BaseModel):
    id: int
    name: str
    email: str
    is_active: bool = True

# Bad: Missing type hints
class User(BaseModel):
    id = None
    name = None
```

### 2. Define Defaults Properly

```python
# Good: Use default_factory for mutable objects
class User(BaseModel):
    tags: List[str] = Field(default_factory=list)
    metadata: dict = Field(default_factory=dict)

# Bad: Mutable default argument
class User(BaseModel):
    tags: List[str] = []
    metadata: dict = {}
```

### 3. Use Constrained Types

```python
# Good: Constrained types
class User(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    age: int = Field(ge=0, le=150)

# Bad: Unconstrained validation in handler
class User(BaseModel):
    username: str
    age: int
    
    @field_validator('username')
    def validate_username(self, v):
        if len(v) < 3 or len(v) > 20:
            raise ValueError('Invalid username')
        return v
```

### 4. Separate Schemas

```python
# Good: Separate schemas for different operations
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    username: str
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None

class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    model_config = {'from_attributes': True}
```

## Common Issues

### Performance

```python
# Issue: Slow validation
# Solution: Use Pydantic v2 (much faster)
# pip install pydantic>=2.0.0

# Solution: Use orjson for serialization
# pip install orjson

import orjson

class FastModel(BaseModel):
    model_config = {'json_loads': orjson.loads, 'json_dumps': orjson.dumps}
```

### Mutable Defaults

```python
# Issue: Mutable default arguments
# Error in Pydantic v2
class BadModel(BaseModel):
    items: list = []

# Solution: Use default_factory
class GoodModel(BaseModel):
    items: list = Field(default_factory=list)
```

### Validation Order

```python
# Issue: Validator order
# In Pydantic v2, field_validators run in order of definition
# mode='before' validators run first, then field type validation, then 'after'

class OrderedValidation(BaseModel):
    value: str
    
    @field_validator('value', mode='before')
    @classmethod
    def before_validation(cls, v):
        return v.strip().lower() if isinstance(v, str) else v
    
    @field_validator('value')
    @classmethod
    def after_validation(cls, v):
        return v
```

## References

- **Official Documentation**: https://docs.pydantic.dev/
- **GitHub Repository**: https://github.com/pydantic/pydantic
- **Pydantic Discord**: https://discord.gg/pydantic
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/pydantic