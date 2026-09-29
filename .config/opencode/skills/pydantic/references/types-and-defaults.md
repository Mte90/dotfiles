# Types and Defaults

This reference file is loaded on demand from ../SKILL.md.

## Alias and Naming

### Field Aliases

```python
from pydantic import BaseModel, Field, AliasChoices

class UserWithAlias(BaseModel):
    # Use alias for input, different name for code
    user_id: int = Field(alias='userId')
    first_name: str = Field(alias='firstName')
    last_name: str = Field(alias='lastName')
    email_address: str = Field(validation_alias='email')

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
    display_name: str = Field(default="")
    
    @field_validator('display_name', mode='before')
    @classmethod
    def use_username_as_display_name(cls, v, info):
        if v == "":
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
    user_uuid: UUID1
    session_uuid: UUID4
    
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