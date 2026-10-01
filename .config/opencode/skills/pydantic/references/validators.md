# Validators Reference

This reference file is loaded on demand from ../SKILL.md.

## Field Validators

Single-field validation with `@field_validator`.

```python
from pydantic import BaseModel, field_validator, Field
import re

class User(BaseModel):
    username: str
    email: str
    age: int
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        # Strip and lowercase
        v = v.strip().lower()
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username can only contain letters, numbers, underscores')
        return v
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if '@' not in v:
            raise ValueError('Invalid email format')
        return v.lower()
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 0 or v > 150:
            raise ValueError('Age must be between 0 and 150')
        return v
```

### Multiple Validators on Same Field

Validators run in order of definition.

```python
class ValidatedField(BaseModel):
    value: str
    
    @field_validator('value')
    @classmethod
    def strip_whitespace(cls, v: str) -> str:
        return v.strip()
    
    @field_validator('value')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        if not v:
            raise ValueError('Value cannot be empty')
        return v
    
    @field_validator('value')
    @classmethod
    def validate_length(cls, v: str) -> str:
        if len(v) > 100:
            raise ValueError('Value too long')
        return v
```

### Mode: Before vs After

- `mode='before'`: Runs before type coercion (can transform input)
- `mode='after'`: Runs after type coercion (can validate final value)

```python
from pydantic import BaseModel, field_validator

class ModeExample(BaseModel):
    value: str
    
    @field_validator('value', mode='before')
    @classmethod
    def before_validation(cls, v):
        # Runs before type coercion
        if isinstance(v, str):
            return v.strip().lower()
        return str(v)
    
    @field_validator('value', mode='after')
    @classmethod
    def after_validation(cls, v):
        # Runs after type coercion (v is already str)
        if len(v) < 3:
            raise ValueError('Too short')
        return v
```

## Model Validators

Cross-field validation with `@model_validator`.

```python
from pydantic import BaseModel, model_validator, Field
from typing import Any

class PasswordMatch(BaseModel):
    password: str
    confirm_password: str
    
    @model_validator(mode='before')
    @classmethod
    def check_passwords_match(cls, data: Any) -> Any:
        # Runs before any field validation
        if isinstance(data, dict):
            if data.get('password') != data.get('confirm_password'):
                raise ValueError('Passwords do not match')
        return data

class DateRange(BaseModel):
    start_date: str
    end_date: str
    
    @model_validator(mode='after')
    def validate_dates(self):
        # Runs after all field validation
        from datetime import datetime
        start = datetime.fromisoformat(self.start_date)
        end = datetime.fromisoformat(self.end_date)
        
        if end < start:
            raise ValueError('End date must be after start date')
        
        return self
```

### Mode: Before vs After for Model Validators

- `mode='before'`: Receives raw input (dict, etc.), can modify before field validation
- `mode='after'`: Receives validated model instance, can validate final state

```python
class ModelValidatorModes(BaseModel):
    username: str
    password: str
    
    @model_validator(mode='before')
    @classmethod
    def before_model_validation(cls, data: Any) -> Any:
        # Can add/modify fields before any validation
        if isinstance(data, dict):
            data['username'] = data.get('username', '').strip().lower()
        return data
    
    @model_validator(mode='after')
    def after_model_validation(self):
        # Can validate final model state
        if self.username.lower() in self.password.lower():
            raise ValueError('Username in password')
        return self
```

## TypeAdapter

Validate arbitrary types without a model.

```python
from pydantic import TypeAdapter, ValidationError
from typing import List, Optional, Dict

# List of strings
ta_list = TypeAdapter(List[str])
validated = ta_list.validate_python(["a", "b", "c"])
validated_json = ta_list.validate_json('["x", "y", "z"]')

# Dict with int values
ta_dict = TypeAdapter(Dict[str, int])
validated = ta_dict.validate_python({"a": 1, "b": 2})

# Type coercion
ta_int = TypeAdapter(int)
result = ta_int.validate_python("42")  # 42

# Dump
output = ta_list.dump_json(["hello", "world"])
```

## RootModel

Collection-only schemas without a wrapper field.

```python
from pydantic import RootModel
from typing import List

class StringList(RootModel[List[str]]):
    """List of strings - no parent wrapper."""
    
    @property
    def labels(self) -> List[str]:
        return [item.upper() for item in self.root]

# Usage
strings = StringModel(root=["apple", "banana", "cherry"])
print(strings.root)  # ["apple", "banana", "cherry"]
print(strings.labels)  # ["APPLE", "BANANA", "CHERRY"]

# From JSON
json_data = '["dog", "cat", "bird"]'
pets = StringList.model_validate_json(json_data)
```

## Discriminated Unions

Route to correct model based on a discriminator field.

```python
from pydantic import BaseModel, Field, Discriminator
from typing import Union, Literal, Annotated

class Cat(BaseModel):
    pet_type: Literal["cat"] = "cat"
    meows: int

class Dog(BaseModel):
    pet_type: Literal["dog"] = "dog"
    barks: float

class Zoo(BaseModel):
    pet: Annotated[
        Union[Cat, Dog],
        Discriminator(tag='pet_type')
    ]

# Pydantic routes based on pet_type
zoo = Zoo(pet={"pet_type": "cat", "meows": 5})
print(zoo.pet)  # Cat(pet_type='cat', meows=5)
```

## Error Handling

```python
from pydantic import BaseModel, ValidationError

class User(BaseModel):
    id: int
    username: str
    email: str

try:
    user = User(id="not_an_int", username="jo", email="invalid")
except ValidationError as e:
    # e.errors() returns list of error dicts
    for error in e.errors():
        print(f"Field: {error['loc']}")
        print(f"Message: {error['msg']}")
        print(f"Type: {error['type']}")
        print(f"Input: {error['input']}")
    
    # e.error_count() gives count
    print(f"Total errors: {e.error_count()}")
```

## Custom Error Messages

```python
from pydantic import BaseModel, field_validator, Field

class ValidatedUser(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    age: int = Field(ge=0, le=150)
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if not v.isalnum():
            raise ValueError('Username must be alphanumeric')
        return v.lower()
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 18:
            raise ValueError('Must be at least 18')
        return v
```

## Source URLs

- Validators: https://docs.pydantic.dev/latest/concepts/validators/
- TypeAdapter: https://docs.pydantic.dev/latest/api/type_adapter/
- RootModel: https://docs.pydantic.dev/latest/api/root_model/
- Discriminated Unions: https://docs.pydantic.dev/latest/concepts/unions/#discriminated-unions
