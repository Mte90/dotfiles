# Validation Patterns

This reference file is loaded on demand from ../SKILL.md.

## TypeAdapter

### TypeAdapter for Custom Validation

```python
from pydantic import TypeAdapter, ValidationError
from typing import List, Optional, Any

# TypeAdapter for custom validation on arbitrary objects
ta_list_str = TypeAdapter(List[str])

# Validate arbitrary data against the adapter
data = ["a", "b", "c"]
validated = ta_list_str.validate_python(data)
print(validated)  # ["a", "b", "c"]

# Validate from JSON
json_data = '["x", "y", "z"]'
validated_json = ta_list_str.validate_json(json_data)
print(validated_json)  # ["x", "y", "z"]

# Convert to JSON
output = ta_list_str.dump_json(["hello", "world"])
print(output)  # b'["hello","world"]'

# Using TypeAdapter for type coercion
ta_int = TypeAdapter(int)
result = ta_int.validate_python("42")
print(result)  # 42

# TypeAdapter for complex nested types
from typing import Dict
ta_dict = TypeAdapter(Dict[str, int])
nested_data = {"a": 1, "b": 2, "c": 3}
validated_nested = ta_dict.validate_python(nested_data)

# TypeAdapter for custom error messages
class CustomIntError(BaseException):
    pass

ta_custom = TypeAdapter(int)
try:
    ta_custom.validate_python("not a number")
except ValidationError as e:
    print(f"Validation failed: {e.errors()[0]['msg']}")
```

## RootModel

### RootModel for Collection-Only Schemas

```python
from pydantic import RootModel
from typing import List, Optional

# RootModel for collection-only schemas
class StringList(RootModel[List[str]]):
    """Root model for list of strings - no parent wrapper."""
    
    @property
    def labels(self) -> List[str]:
        """Derived property for list items."""
        return [item.upper() for item in self.root]

# Usage with list of strings
strings = StringList(root=["apple", "banana", "cherry"])
print(strings.root)  # ["apple", "banana", "cherry"]
print(strings.labels)  # ["APPLE", "BANANA", "CHERRY"]

# From JSON
json_data = '["dog", "cat", "bird"]'
pets = StringList.model_validate_json(json_data)
print(pets)  # StringList(root=['dog', 'cat', 'bird'])

# Optional root
class OptionalList(RootModel[Optional[List[str]]]):
    """Root model with optional root."""
    pass

optional = OptionalList(root=["a", "b"])
empty = OptionalList(root=None)
print(optional.root)  # ["a", "b"]
print(empty.root)  # None

# Multiple types with RootModel
class NumberList(RootModel[List[int]]):
    """List of numbers."""
    pass

numbers = NumberList(root=[1, 2, 3])
print(numbers.model_dump())  # [1, 2, 3]
```

## Discriminated Unions

### Basic Discriminated Union

```python
from pydantic import BaseModel, Field, Discriminator
from typing import Union, Annotated

class Cat(BaseModel):
    pet_type: str = Field(default="cat", const=True)
    meows: int

class Dog(BaseModel):
    pet_type: str = Field(default="dog", const=True)
    barks: float

class Zoo(BaseModel):
    pet: Union[Cat, Dog] = Field(..., discriminator='pet_type')

# Pydantic v2 style
class ZooV2(BaseModel):
    pet: Annotated[
        Union[Cat, Dog],
        Discriminator(tag='pet_type')
    ]

# This is how it's done in API responses with multiple types
class ApiResponse(BaseModel):
    status: str
    data: Union[Cat, Dog] = Field(..., discriminator='pet_type')

# Usage
response = ApiResponse(
    status="success",
    data={"pet_type": "cat", "meows": 5}
)
print(response.data)  # Cat(meows=5)
```

### Advanced Discriminated Union

```python
from pydantic import BaseModel, Field, Discriminator
from typing import Union, Literal, Annotated

class Image(BaseModel):
    type: Literal["image"]
    url: str
    format: Literal["jpg", "png", "gif"]

class Video(BaseModel):
    type: Literal["video"]
    url: str
    duration: int
    format: Literal["mp4", "webm"]

class Document(BaseModel):
    type: Literal["document"]
    pages: int
    format: Literal["pdf", "docx"]

# API Response with multiple media types
class MediaResponse(BaseModel):
    id: int
    title: str
    media: Annotated[
        Union[Image, Video, Document],
        Discriminator(tag='type')
    ]
    created_at: str

# Pydantic automatically routes based on discriminator
response = MediaResponse(
    id=1,
    title="My Video",
    media={"type": "video", "url": "https://example.com/video.mp4", "duration": 120, "format": "mp4"},
    created_at="2024-01-01T00:00:00Z"
)
print(response.media)  # Video(duration=120, url='https://example.com/video.mp4', format='mp4')
```

## Error Handling

### Error Handling with ValidationError

```python
from pydantic import BaseModel, ValidationError
from typing import List, Optional

# API response handling with error formatting
class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    age: int

# Try/except for API responses
def fetch_user_from_api(api_data):
    try:
        user = UserResponse(**api_data)
        return {"success": True, "data": user}
    except ValidationError as e:
        errors = e.errors()
        formatted_errors = {
            error['loc'][0]: {
                'message': error['msg'],
                'type': error['type'],
                'input': error['input']
            }
            for error in errors
            if error['loc'] and len(error['loc']) > 0
        }
        return {
            "success": False,
            "errors": formatted_errors
        }

# Example usage
valid_data = {"id": 1, "username": "john", "email": "john@example.com", "age": 30}
invalid_data = {"id": "not_an_int", "username": "jo", "email": "invalid", "age": -5}

result = fetch_user_from_api(valid_data)
print(result["success"])  # True

result = fetch_user_from_api(invalid_data)
print(result["success"])  # False
print(result["errors"])  # Formatted error dict

# Error details in e.errors()
try:
    user = UserResponse(id="not an int", name="John", age="not an int")
except ValidationError as e:
    print(e.errors())
    # [
    #     {
    #         'type': 'int_parsing',
    #         'loc': ('id',),
    #         'msg': 'Input should be a valid integer',
    #         'input': 'not an int'
    #     },
    #     {
    #         'type': 'int_parsing',
    #         'loc': ('age',),
    #         'msg': 'Input should be a valid integer',
    #         'input': 'not an int'
    #     }
    # ]
    
    print(e)
    # 2 validation errors for UserResponse
    # id
    #   Input should be a valid integer [type=int_parsing, input_value='not an int', input_type=str]
    # age
    #   Input should be a valid integer [type=int_parsing, input_value='not an int', input_type=str]

# Custom error messages in field validators
from pydantic import field_validator

class AgeUser(BaseModel):
    age: int
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v):
        if v < 0:
            raise ValueError('Age must be a positive number')
        if v > 150:
            raise ValueError('Are you really that old?')
        return v

try:
    AgeUser(age=-5)
except ValidationError as e:
    print(e.error_count())  # 1
    for error in e.errors():
        print(f"Field: {error['loc']}")
        print(f"Message: {error['msg']}")
        print(f"Input: {error['input']}")
```