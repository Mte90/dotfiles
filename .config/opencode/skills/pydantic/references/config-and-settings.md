# Configuration and Settings

This reference file is loaded on demand from ../SKILL.md.

## Configuration

### Model Config

```python
from pydantic import BaseModel, ConfigDict
from typing import Optional

# Pydantic v2 style
class User(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        arbitrary_types_allowed=True,
        use_enum_values=True,
        populate_by_name=True,
        extra='forbid',
        frozen=True,
        strict_fields=False,
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
    value: str = Field(default="test", validate_default=True)
```

### Advanced Config Patterns

#### Strict Mode and Extra Fields

```python
from pydantic import BaseModel, ConfigDict, Field
from typing import Any, Optional

# Strict mode with extra allowed
class StrictWithExtra(BaseModel):
    model_config = ConfigDict(
        strict=False,
        extra="allow"
    )
    
    id: int
    name: str
    metadata: Optional[dict] = None
    extra_data: Any = Field(default=None)

# This accepts extra fields without error
data = {"id": 1, "name": "John", "extra_field": "allowed"}
user = StrictWithExtra(**data)
print(user.extra_field)  # "allowed"

# Strict mode with forbid (default)
class StrictModel(BaseModel):
    model_config = ConfigDict(strict=True, extra="forbid")
    
    id: int
    name: str
```

#### Multi-Environment Settings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
import os

class DatabaseSettings(BaseSettings):
    """Database configuration."""
    model_config = SettingsConfigDict(
        env_file='.env.prod',
        env_nested_delimiter='__',
    )
    
    host: str = "localhost"
    port: int = 5432
    name: str
    user: str
    password: str

class DevSettings(BaseSettings):
    """Development settings."""
    model_config = SettingsConfigDict(
        env_file='.env.dev',
    )
    
    debug: bool = True
    host: str = "127.0.0.1"
    port: int = 8000

class ProdSettings(BaseSettings):
    """Production settings."""
    model_config = SettingsConfigDict(
        env_file='.env.prod',
    )
    
    debug: bool = False
    host: str = os.getenv("DATABASE_HOST", "db.prod.example.com")
    port: int = 5432

# Use environment-aware settings
env = os.getenv("ENVIRONMENT", "dev")
if env == "prod":
    settings = ProdSettings()
else:
    settings = DevSettings()
```

#### Nested Structure Config

```python
from pydantic import BaseModel, ConfigDict
from typing import Dict, Any, Optional

class APIConfig(BaseModel):
    """Nested API configuration."""
    model_config = ConfigDict(
        extra="allow",
    )
    
    timeout: int = 30
    retries: int = 3
    endpoints: Dict[str, Any] = {}

class Application(BaseModel):
    """Application with nested config structures."""
    model_config = ConfigDict(
        str_strip_whitespace=True,
    )
    
    app_name: str
    version: str
    api: APIConfig = Field(default_factory=APIConfig)
    features: Dict[str, bool] = {}

# Usage
app = Application(
    app_name="MyApp",
    version="1.0.0",
    api={"timeout": 60, "retries": 5, "custom_setting": "extra"}
)
```

## Settings/BaseSettings

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
    
    model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8')

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