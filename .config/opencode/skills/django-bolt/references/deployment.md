# Deep Dive: Loaded on demand from django-bolt/SKILL.md

## Deployment

### systemd Service

```ini
# /etc/systemd/system/django-bolt.service
[Unit]
Description=Django-Bolt API Server
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/your/project
ExecStart=/path/to/venv/bin/python manage.py runbolt --host 127.0.0.1 --port 8000 --processes 4
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable django-bolt
sudo systemctl start django-bolt
sudo systemctl status django-bolt
```

### supervisor

```ini
# /etc/supervisor/conf.d/django-bolt.conf
[program:django-bolt]
command=/path/to/venv/bin/python manage.py runbolt --host 127.0.0.1 --port 8000 --processes 4
directory=/path/to/your/project
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/django-bolt.log
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start django-bolt
```

### Reverse Proxy with nginx

```nginx
upstream django_bolt {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://django_bolt;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Database Connections

#### psycopg pool (recommended for Django 5.1+)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "USER": "myuser",
        "PASSWORD": "mypassword",
        "HOST": "localhost",
        "CONN_MAX_AGE": 0,
        "OPTIONS": {
            "pool": {
                "min_size": 2,
                "max_size": 10,
            }
        },
    }
}
```

#### PgBouncer (external pooler)

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "HOST": "127.0.0.1",
        "PORT": "6432",  # PgBouncer port
        "CONN_MAX_AGE": 0,
        "DISABLE_SERVER_SIDE_CURSORS": True,
    }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runbolt", "--host", "0.0.0.0", "--port", "8000", "--processes", "4"]
```

```yaml
# docker-compose.yml
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
```

### Workers vs Processes

Django Bolt uses processes for parallelism, not workers. Each process has its own GIL:

```bash
# Use processes for parallelism (not workers)
python manage.py runbolt --processes 4

# Rule of thumb: set --processes to number of CPU cores
```

---

## MCP Servers (v0.11.0+)

Django Bolt includes built-in MCP (Model Context Protocol) server support.

### Installation

```bash
pip install "django-bolt[mcp]"
```

### Mount MCP

```python
from django_bolt.mcp import mount_mcp

api = BoltAPI()
mount_mcp(api)  # Mounts MCP endpoints at /mcp
```

- SSE-based transport for streaming
- Resource templates with variable substitution

### Example: Custom MCP Tool

```python
from django_bolt.mcp import mount_mcp, mcp_tool
from django_bolt import BoltAPI

api = BoltAPI()

@mcp_tool(description="Get user by ID")
async def get_user(user_id: int) -> dict:
    user = await User.objects.aget(id=user_id)
    return {"id": user.id, "username": user.username, "email": user.email}

mount_mcp(api, tools=[get_user])
```

### Example: MCP Resource

```python
from django_bolt.mcp import mcp_resource

@mcp_resource(uri="user://{user_id}", description="User profile")
async def user_profile(user_id: int) -> str:
    user = await User.objects.aget(id=user_id)
    return f"User: {user.username} ({user.email})"

mount_mcp(api, resources=[user_profile])
```

See https://bolt.farhana.li/topics/mcp/ for full documentation.

---