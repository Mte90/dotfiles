# FastAPI Integration

This reference file is loaded on demand from ../SKILL.md.

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
            tax=item.price * 0.1
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