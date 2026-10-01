# Django Integration

This reference file is loaded on demand from ../SKILL.md.

## ORM Object Acceptance

Pydantic v2 accepts Django ORM objects via `from_attributes=True`.

```python
from pydantic import BaseModel, ConfigDict
from myapp.models import User as UserModel, Post as PostModel

class UserPydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    username: str
    email: str
    is_active: bool

# Direct ORM acceptance
user_orm = UserModel.objects.get(id=1)
user_py = UserPydantic.model_validate(user_orm)

# Nested ORM objects
class PostPydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    title: str
    author: UserPydantic  # Nested ORM object

post_orm = PostModel.objects.select_related('author').get(id=1)
post_py = PostPydantic.model_validate(post_orm)
```

**Important**: Use `select_related()`/`prefetch_related()` to avoid N+1 queries when validating nested ORM objects.

## DjangoChoices for Enum Validation

Django `TextChoices`/`IntChoices` work seamlessly with Pydantic enum validation.

```python
from django.db import models

class Status(models.TextChoices):
    PENDING = "pending", "Pending"
    ACTIVE = "active", "Active"
    COMPLETED = "completed", "Completed"

class Priority(models.IntChoices):
    LOW = 1
    MEDIUM = 2
    HIGH = 3

from pydantic import BaseModel

class Task(BaseModel):
    status: Status  # Works - validates against choices
    priority: Priority  # Works - validates against choices

# Valid
task = Task(status="pending", priority=1)  # Coerced to Status.PENDING, Priority.LOW

# Invalid - raises ValidationError
task = Task(status="invalid", priority=1)  # Error: input should be 'pending', 'active' or 'completed'
```

**Why `TextChoices` is required**: Plain `str` enums don't work for Django model field validation. `TextChoices`/`IntChoices` provide the string/integer values that Pydantic validates against.

## DjangoGetter for Lazy Evaluation

For lazy model field access (avoiding N+1 queries), wrap with `DjangoGetter`.

```python
from pydantic import BaseModel, ConfigDict
from django.db import models

class DjangoGetter:
    """Wrapper for lazy Django model field access."""
    def __init__(self, obj, schema_cls):
        self.obj = obj
        self.schema_cls = schema_cls

    def __getattr__(self, key):
        # Lazy access - only fetches when field is accessed
        return getattr(self.obj, key)

# Usage pattern
class UserPydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    username: str
    email: str

# When validating queryset results
from myapp.models import User

queryset = User.objects.all()
for user_orm in queryset:
    # DjangoGetter prevents N+1 when accessing nested fields
    user_py = UserPydantic.model_validate(DjangoGetter(user_orm, UserPydantic))
```

## Unsaved Instance Pitfall

Validating an unsaved Django model instance may fail if validators expect DB-generated fields.

```python
from django.db import models
from pydantic import BaseModel, ConfigDict, field_validator

class UserPydantic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int  # DB-generated
    username: str
    email: str

# Unsaved instance - id is None
user_orm = User(username="john", email="john@example.com")
# user_orm.save()  # Uncomment to persist

# This may fail if id is required
try:
    user_py = UserPydantic.model_validate(user_orm)
except Exception as e:
    print(f"Validation failed: {e}")

# Fix: make id optional or handle None
class UserPydanticOptional(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int | None = None  # Optional for unsaved instances
    username: str
    email: str
```

## Model Forms and Request Data

```python
from django import forms
from pydantic import BaseModel, ValidationError

class UserForm(forms.Form):
    username = forms.CharField(max_length=100)
    email = forms.EmailField()

class UserPydantic(BaseModel):
    username: str
    email: str

def handle_form(request):
    if request.method == "POST":
        form = UserForm(request.POST)
        if form.is_valid():
            # Convert form data to Pydantic model
            try:
                user = UserPydantic(**form.cleaned_data)
                # Process validated data
            except ValidationError as e:
                # Handle Pydantic validation errors
                errors = e.errors()
```

## Source URLs

- Pydantic Django docs: https://docs.pydantic.dev/latest/integrations/django/
- Django ORM: https://docs.djangoproject.com/en/stable/topics/db/
