---
name: pydantic
description: "Data validation using Python type hints with Pydantic models, settings, serialization, and performance optimization"
metadata:
  author: "OSS AI Skills"
  version: "1.0.0"
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
from typing import Optional, List, Dict, Set, Tuple, Union, Any

class AllTypesExample(BaseModel):
    # Primitives
    string: str
    integer: int
    floating: float
    boolean: bool
    bytes: bytes
    
    # Optional
    optional_string: Optional[str] = None
    optional_with_default: Optional[int] = 42
    
    # Collections
    list_of_strings: List[str] = []
    list_of_ints: List[int]
    dict_data: Dict[str, int] = {}
    set_of_ints: Set[int] = set()
    tuple_data: Tuple[int, str, float] = (1, "a", 1.5)
    
    # Union
    union_field: Union[int, str] = 1
    
    # Any
    any_field: Any = "anything"
    
    # Literal
    from typing import Literal
    status: Literal["pending", "active", "completed"] = "pending"
```

### Nested Models

```python
from pydantic import BaseModel
from typing import List, Optional

class Address(BaseModel):
    street: str
    city: str
    country: str
    postal_code: Optional[str] = None

class Company(BaseModel):
    name: str
    address: Address
    employees: List[str] = []

class Person(BaseModel):
    name: str
    email: str
    address: Optional[Address] = None
    company: Optional[Company] = None

# Create nested data
person = Person(
    name="John",
    email="john@example.com",
    address=Address(
        street="123 Main St",
        city="New York",
        country="USA"
    ),
    company=Company(
        name="Tech Corp",
        address=Address(
            street="456 Business Ave",
            city="San Francisco",
            country="USA"
        ),
        employees=["Alice", "Bob"]
    )
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
    age: int = Field(ge=0, le=150)  # greater or equal, less or equal
    price: float = Field(gt=0)      # greater than
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
        return v.strip()  # First: strip whitespace
    
    @field_validator('value')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        if not v:
            raise ValueError('Value cannot be empty')
        return v  # Then: check not empty
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

# Root validator (alias for model_validator in v1)
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
data = user.model_dump(include={'id', 'name'})  # Only id and name
data = user.model_dump(exclude={'metadata'})     # Everything except metadata
```

### Advanced Serialization

```python
from pydantic import BaseModel, Field, SerializerFunctionWrap
from typing import List, Optional
from datetime import datetime

class User(BaseModel):
    id: int
    name: str
    created_at: datetime
    
    # Custom serialization
    @property
    def display_name(self) -> str:
        return f"#{self.id} - {self.name}"
    
    # Custom field serializer
    @field_serializer('created_at')
    def serialize_datetime(self, dt: datetime) -> str:
        return dt.isoformat()

user = User(id=1, name="John", created_at=datetime.now())

# Serialization options
data = user.model_dump(
    mode='json',           # Convert to JSON-serializable types
    include={'id', 'name'},
    exclude={'created_at'},
    by_alias=True,         # Use field aliases
    exclude_none=True,    # Exclude None values
    exclude_unset=True,   # Exclude unset fields
    exclude_defaults=True # Exclude default values
)
```

### Model Validate

```python
from pydantic import BaseModel
from typing import Optional

class User(BaseModel):
    id: int
    name: str
    email: str

# From dictionary
data = {"id": 1, "name": "John", "email": "john@example.com"}
user = User.model_validate(data)

# From JSON string
json_str = '{"id": 2, "name": "Jane", "email": "jane@example.com"}'
user = User.model_validate_json(json_str)

# From object
class SomeClass:
    def __init__(self):
        self.id = 3
        self.name = "Bob"
        self.email = "bob@example.com"

obj = SomeClass()
user = User.model_validate(obj)

# Partial update
data = {"name": "Updated Name"}
user = User.model_validate(data, update={"id": 1, "email": "old@example.com"})
```

### JSON Schema

```python
from pydantic import BaseModel

class User(BaseModel):
    id: int
    name: str
    email: str

# Generate JSON Schema
schema = User.model_json_schema()
print(schema)

# With configuration
class ConfiguredUser(BaseModel):
    model_config = {'title': 'User Model', 'description': 'A user model'}
    
    id: int
    name: str

schema = ConfiguredUser.model_json_schema()
```

## Alias and Naming

### Field Aliases

```python
from pydantic import BaseModel, Field, AliasChoices

class UserWithAlias(BaseModel):
    # Use alias for input, different name for code
    user_id: int = Field(alias='userId')
    first_name: str = Field(alias='firstName')
    last_name: str = Field(alias='lastName')
    email_address: str = Field(validation_alias='email')  # AliasChoices for multiple

# Populate using alias
data = {"userId": 1, "firstName": "John", "lastName": "Doe", "email": "john@example.com"}
user = UserWithAlias.model_validate(data)

# Access by Python name
print(user.user_id)
print(user.first_name)

# Serialize with alias
json_data = user.model_dump(by_alias=True)
# {'userId': 1, 'firstName': 'John', 'lastName': 'Doe', 'email': 'john@example.com'}
```

### Alias Generator

```python
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel, to_snake, to_pascal

class CamelCaseUser(BaseModel):
    """User with camelCase serialization."""
    model_config = ConfigDict(alias_generator=to_camel)
    
    user_id: int
    first_name: str
    last_name: str
    email_address: str

user = CamelCaseUser(
    user_id=1,
    first_name="John",
    last_name="Doe",
    email_address="john@example.com"
)

# Serialized as camelCase
print(user.model_dump(by_alias=True))
# {'userId': 1, 'firstName': 'John', 'lastName': 'Doe', 'emailAddress': 'john@example.com'}
```

## Default Values

### Field Defaults

```python
from pydantic import BaseModel, Field
from typing import Optional, List

class DefaultsExample(BaseModel):
    # Simple default
    name: str = "Unknown"
    
    # Default with type
    age: int = 25
    
    # Optional with default None
    nickname: Optional[str] = None
    
    # Required (no default)
    email: str
    
    # Field with default
    tags: List[str] = Field(default_factory=list)
    
    # Field with factory
    items: List[int] = Field(default_factory=lambda: [1, 2, 3])
    
    # Default factory for mutable objects (important!)
    metadata: dict = Field(default_factory=dict)
    scores: List[int] = Field(default_factory=list)

# Using default_factory for complex defaults
import uuid
class WithFactory(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    created_at: str = Field(default_factory=lambda: "generated_value")
```

### Default Values with Validators

```python
from pydantic import BaseModel, field_validator, Field
from typing import Optional

class UserWithDefaultValidator(BaseModel):
    username: str
    # Validator runs even with default
    display_name: str = Field(default="")
    
    @field_validator('display_name', mode='before')
    @classmethod
    def use_username_as_display_name(cls, v, info):
        # If display_name not provided, use username
        if v == "":
            # info.data contains other field values
            return info.data.get('username', 'Unknown')
        return v

# Without display_name - uses username
user = UserWithDefaultValidator(username="john")
print(user.display_name)  # "john"

# With display_name - uses provided value
user = UserWithDefaultValidator(username="john", display_name="John Doe")
print(user.display_name)  # "John Doe"
```

## Constrained Types

### String Constraints

```python
from pydantic import BaseModel, Field, constr

# Using Field
class FieldConstraints(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    password: str = Field(min_length=8)
    slug: str = Field(pattern=r'^[a-z0-9-]+$')

# Using constrained types
class ConstrainedTypes(BaseModel):
    # constr creates a constrained string type
    username: constr(min_length=3, max_length=20)
    password: constr(min_length=8)
    slug: constr(pattern=r'^[a-z0-9-]+$')
    email: constr(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')

user = ConstrainedTypes(
    username="john_doe",
    password="secret123",
    slug="my-blog-post",
    email="john@example.com"
)
```

### Numeric Constraints

```python
from pydantic import BaseModel, Field, conint, confloat, conlist

class NumericConstraints(BaseModel):
    # Integer constraints
    quantity: conint(ge=0, le=1000)
    age: conint(ge=0, le=150)
    
    # Float constraints
    price: confloat(gt=0)
    rating: confloat(ge=0.0, le=5.0)
    
    # List constraints
    scores: conlist(int, min_length=1, max_length=10)
    codes: conlist(str, min_length=3)

product = NumericConstraints(
    quantity=10,
    age=25,
    price=19.99,
    rating=4.5,
    scores=[90, 85, 95],
    codes=["ABC", "DEF"]
)
```

## Special Types

### Email, URL, UUID

```python
from pydantic import BaseModel, EmailStr, HttpUrl, UUID1, UUID4, PaymentCardNumber
from typing import Optional
import uuid

class ContactInfo(BaseModel):
    # Email validation
    email: EmailStr
    secondary_email: Optional[EmailStr] = None
    
    # URL validation
    website: HttpUrl
    api_endpoint: Optional[HttpUrl] = None
    
    # UUID
    user_uuid: UUID1  # UUID version 1
    session_uuid: UUID4  # UUID version 4
    
    # Payment card (Luhn validation)
    card_number: Optional[PaymentCardNumber] = None

contact = ContactInfo(
    email="user@example.com",
    website="https://example.com",
    user_uuid=uuid.uuid1(),
    session_uuid=uuid.uuid4()
)
```

### Secret Types

```python
from pydantic import BaseModel, SecretStr, SecretBytes

class Credentials(BaseModel):
    # Masks value in output
    password: SecretStr
    api_key: Optional[SecretStr] = None
    
    # For binary secrets
    encryption_key: SecretBytes

creds = Credentials(password="secret123")

# Access the secret
print(creds.password)              # SecretStr('**********')
print(creds.password.get_secret_value())  # "secret123"

# Serialization
data = creds.model_dump()
# {'password': SecretStr('**********'), 'api_key': None, 'encryption_key': SecretBytes(b'**********')}
```

### Enum Types

```python
from pydantic import BaseModel, StrEnum, IntEnum
from enum import Enum

class Status(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"

class Priority(int, Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3

class Task(BaseModel):
    # Works with any enum
    status: Status = Status.PENDING
    priority: Priority = Priority.MEDIUM

task = Task(status=Status.ACTIVE, priority=Priority.HIGH)

# StringEnum (Pydantic v2)
class UserRole(StrEnum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class User(BaseModel):
    role: UserRole = UserRole.GUEST
```

## Configuration

### Model Config

```python
from pydantic import BaseModel, ConfigDict
from typing import Optional

# Pydantic v2 style
class User(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,      # Strip whitespace from strings
        validate_assignment=True,       # Validate on assignment
        arbitrary_types_allowed=True,   # Allow arbitrary types
        use_enum_values=True,           # Use enum values (not enum objects)
        populate_by_name=True,          # Allow population by name (not alias)
        extra='forbid',                 # Forbid extra fields
        frozen=True,                    # Make model immutable
    )
    
    id: int
    name: str
    email: Optional[str] = None

# v1 style (still works)
class UserV1(BaseModel):
    class Config:
        str_strip_whitespace = True
        validate_assignment = True
    
    id: int
    name: str
```

### Field-Level Config

```python
from pydantic import BaseModel, Field, field_config

@field_config(validate_default=True)
def validated_field():
    return Field(default="default_value")

class ModelWithFieldConfig(BaseModel):
    # This field will be validated even with default
    value: str = Field(default="test", validate_default=True)
```

## Inheritance

### Model Inheritance

```python
from pydantic import BaseModel
from typing import Optional

class BaseUser(BaseModel):
    id: int
    name: str
    email: str

class UserWithAge(BaseUser):
    age: Optional[int] = None

class AdminUser(UserWithAge):
    is_admin: bool = True
    permissions: list[str] = []

# Inheritance works
admin = AdminUser(
    id=1,
    name="John",
    email="john@example.com",
    age=30,
    is_admin=True,
    permissions=["read", "write"]
)
```

### Composition

```python
from pydantic import BaseModel
from typing import Optional

class TimestampMixin(BaseModel):
    """Mixin to add timestamps."""
    created_at: str
    updated_at: str

class UserMixin(BaseModel):
    """Mixin to add user fields."""
    name: str
    email: str

class User(TimestampMixin, UserMixin):
    id: int

user = User(
    id=1,
    name="John",
    email="john@example.com",
    created_at="2024-01-01",
    updated_at="2024-01-01"
)
```

## Generic Models

### Generic Models

```python
from pydantic import BaseModel
from typing import Generic, TypeVar, List

T = TypeVar('T')

class Container(BaseModel, Generic[T]):
    """Generic container model."""
    items: List[T] = []
    total: int = 0

class StringContainer(Container[str]):
    pass

class IntContainer(Container[int]):
    pass

# Usage
string_container = StringContainer(items=["a", "b", "c"], total=3)
int_container = IntContainer(items=[1, 2, 3], total=3)

# With bounds
class OrderedModel(BaseModel, Generic[T]):
    item: T
    order: int

class StringOrdered(OrderedModel[str]):
    pass
```

### Nested Generics

```python
from pydantic import BaseModel
from typing import Generic, TypeVar, Optional

K = TypeVar('K')
V = TypeVar('V')

class KeyValue(BaseModel, Generic[K, V]):
    key: K
    value: V

class DataStore(BaseModel, Generic[K, V]):
    items: List[KeyValue[K, V]] = []
    metadata: Optional[dict] = None

# Usage
store = DataStore[str, int](
    items=[
        KeyValue(key="age", value=25),
        KeyValue(key="count", value=10)
    ],
    metadata={"source": "database"}
)
```

## Discriminated Unions

### Basic Discriminated Union

```python
from pydantic import BaseModel, Tag
from typing import Union

class Cat(BaseModel):
    pet_type: str = "cat"
    meows: int

class Dog(BaseModel):
    pet_type: str = "dog"
    barks: float

class Zoo(BaseModel):
    # Using Tag for discriminated union
    pet: Union[Cat, Dog] = Field(..., discriminator='pet_type')

# Pydantic v2 style
from pydantic import Discriminator

class Zoo(BaseModel):
    pet: Annotated[
        Union[Cat, Dog],
        Discriminator(tag='pet_type')
    ]
```

### Advanced Discriminated Union

```python
from pydantic import BaseModel
from typing import Union, Literal

class Image(BaseModel):
    type: Literal["image"]
    url: str

class Video(BaseModel):
    type: Literal["video"]
    url: str
    duration: int

class Document(BaseModel):
    type: Literal["document"]
    pages: int

Media = Union[Image, Video, Document]

class Post(BaseModel):
    title: str
    media: Media

# Pydantic automatically routes based on discriminator
post = Post(
    title="My Post",
    media={"type": "video", "url": "https://example.com/video.mp4", "duration": 120}
)
```

## Validation Errors

### Handling Errors

```python
from pydantic import BaseModel, ValidationError

class User(BaseModel):
    id: int
    name: str
    age: int

try:
    user = User(id="not an int", name="John", age="not an int")
except ValidationError as e:
    # Error details
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
    
    # Human-readable
    print(e)
    # 2 validation errors for User
    # id
    #   Input should be a valid integer [type=int_parsing, input_value='not an int', input_type=str]
    # age
    #   Input should be a valid integer [type=int_parsing, input_value='not an int', input_type=str]
```

### Custom Error Messages

```python
from pydantic import BaseModel, field_validator, ValidationError

class User(BaseModel):
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
    User(age=-5)
except ValidationError as e:
    print(e.error_count())  # 1
    for error in e.errors():
        print(f"Field: {error['loc']}")
        print(f"Message: {error['msg']}")
        print(f"Input: {error['input']}")
```

## Settings

### BaseSettings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    """Application settings from environment variables."""
    
    # Required settings
    app_name: str
    database_url: str
    
    # Optional with defaults
    debug: bool = False
    port: int = 8000
    max_connections: int = 10
    
    # Sensitive settings (will be masked in output)
    secret_key: str
    
    # Settings with aliases
    db_host: str = Field(alias='DATABASE_HOST', default='localhost')
    
    #model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8')

# Usage
# Reads from environment variables and .env file
settings = Settings(
    app_name="My App",
    database_url="postgresql://localhost/mydb",
    secret_key="super-secret"
)

# Access values
print(settings.app_name)
print(settings.debug)

# Configuration via model_config
class SettingsV2(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore'
    )
    
    app_name: str
    debug: bool = False
```

### Nested Settings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class DatabaseSettings(BaseSettings):
    """Database configuration."""
    host: str = "localhost"
    port: int = 5432
    name: str
    user: str
    password: str

class RedisSettings(BaseSettings):
    """Redis configuration."""
    host: str = "localhost"
    port: int = 6379
    db: int = 0

class Settings(BaseSettings):
    """Application settings."""
    app_name: str
    database: DatabaseSettings
    redis: RedisSettings
    
    model_config = SettingsConfigDict(env_nested_delimiter='__')

# Environment variables:
# APP_NAME=MyApp
# DATABASE__HOST=db.example.com
# DATABASE__PORT=5432
# REDIS__HOST=redis.example.com

settings = Settings(
    app_name="MyApp",
    database={"name": "mydb", "user": "user", "password": "pass"},
    redis={}
)
```

## FastAPI Integration

### Request Models

```python
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, EmailStr, Field

app = FastAPI()

class UserCreate(BaseModel):
    """User creation schema."""
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8)
    age: int = Field(ge=0, le=150)

class UserResponse(BaseModel):
    """User response schema (excludes sensitive data)."""
    id: int
    username: str
    email: str
    
    model_config = {'from_attributes': True}

@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate):
    """Create a new user."""
    # Validate and process user data
    # user is already validated!
    new_user = await save_user(user.model_dump())
    return new_user

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get user by ID."""
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Response Models

```python
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

class Item(BaseModel):
    id: int
    name: str
    price: float

class ItemWithTax(BaseModel):
    """Item with calculated tax."""
    id: int
    name: str
    price: float
    tax: float
    
    @classmethod
    def from_item(cls, item: Item):
        return cls(
            id=item.id,
            name=item.name,
            price=item.price,
            tax=item.price * 0.1  # 10% tax
        )

app = FastAPI()

@app.get("/items/{item_id}", response_model=ItemWithTax)
async def get_item(item_id: int):
    item = await get_item_from_db(item_id)
    return ItemWithTax.from_item(item)
```

### Nested Validation

```python
from fastapi import FastAPI
from pydantic import BaseModel, ValidationError

app = FastAPI()

class Address(BaseModel):
    street: str
    city: str
    country: str

class UserWithAddress(BaseModel):
    name: str
    address: Address

@app.post("/users")
async def create_user(user: UserWithAddress):
    return user

# Nested validation error example:
# Request: {"name": "John", "address": {"street": "123 Main"}}
# Error: Validation error for address.city (field required)
```

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
    tags: List[str] = []  # ERROR: mutable default!
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
    items: list = []  # ERROR!

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
        # Runs first
        return v.strip().lower() if isinstance(v, str) else v
    
    @field_validator('value')
    @classmethod
    def after_validation(cls, v):
        # Runs after type validation
        return v
```

## References

- **Official Documentation**: https://docs.pydantic.dev/
- **GitHub Repository**: https://github.com/pydantic/pydantic
- **Pydantic Discord**: https://discord.gg/pydantic
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/pydantic