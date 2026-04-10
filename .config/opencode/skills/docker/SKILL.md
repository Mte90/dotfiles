---
name: docker
description: "Docker - containers, Dockerfile, docker-compose, multi-stage builds, production, CI/CD"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - docker
    - docker-compose
    - containerization
    - deployment
    - ci-cd
    - containers
---

# Docker

Complete guide to containerization with Docker - images, containers, compose, and best practices.

## Dockerfile

### Basic Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### Production Dockerfile (Multi-stage)

```dockerfile
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy virtual environment
COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"

# Copy application
COPY --from=builder /app /app

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Run
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

### requirements.txt

```
# requirements.txt
Django>=5.0
gunicorn>=21.0
psycopg2-binary>=2.9
redis>=5.0
django-redis>=0.9
celery>=5.3
```

## docker-compose.yml

### Development

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - DEBUG=1
      - DATABASE_URL=postgres://postgres:postgres@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  db:
    image: postgres:16
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  celery:
    build: .
    command: celery -A myproject worker -l info
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
```

### Production

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.prod
    ports:
      - "8000:8000"
    environment:
      - DEBUG=0
      - DATABASE_URL=postgres://user:password@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  celery:
    build:
      context: .
      dockerfile: Dockerfile.prod
    command: celery -A myproject worker -l info
    environment:
      - DATABASE_URL=postgres://user:password@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    restart: unless-stopped

  celery-beat:
    build:
      context: .
      dockerfile: Dockerfile.prod
    command: celery -A myproject beat -l info
    environment:
      - DATABASE_URL=postgres://user:password@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    restart: unless-stopped

volumes:
  postgres_data:
```

## Docker Commands

```bash
# Build
docker build -t myapp .

# Run
docker run -p 8000:8000 myapp

# With docker-compose
docker-compose up -d
docker-compose up -d --build
docker-compose logs -f web
docker-compose exec web python manage.py migrate

# Stop
docker-compose down
docker-compose down -v  # Remove volumes
```

## GitHub Actions CI/CD

```yaml
# .github/workflows/docker.yml
name: Docker

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: myuser/myapp
        tags: |
          type=ref,event=branch
          type=ref,event=tag
          type=sha
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: ${{ github.event_name != 'pull_request' }}
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=registry,ref=myuser/myapp:buildcache
        cache-to: type=registry,ref=myuser/myapp:buildcache,mode=max
```

## Best Practices

1. **Use multi-stage builds** for smaller images
2. **Don't run as root** - use USER instruction
3. **Use .dockerignore** to exclude unnecessary files
4. **Use healthchecks** for dependencies
5. **Use volume mounts** for development
6. **Set proper environment variables**
7. **Use gunicorn** in production, not runserver
8. **Scan images for vulnerabilities** - docker scout
9. **Use specific tags** - not :latest in production
10. **Readonly containers** - use --read-only flag

## Docker Compose

### Basic Usage

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DEBUG=1
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=secret

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Compose Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f web

# Scale service
docker compose up -d --scale web=3

# Stop all
docker compose down

# With volumes
docker compose down -v
```

## BuildKit

### Enable BuildKit

```bash
# Enable permanently
export DOCKER_BUILDKIT=1

# Or per-build
DOCKER_BUILDKIT=1 docker build .
```

### BuildKit Features

```dockerfile
# Syntax directive for BuildKit
# syntax=docker/dockerfile:1

# --mount=type=cache for caching layers
FROM node:20
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```

## Multi-platform Builds

```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myapp:latest \
  --push .
```

## Security

### Scan images

```bash
docker scout cves myapp:latest
docker scout recommendations myapp:latest
```

## Production Tips

```bash
# Run with resource limits
docker run -d \
  --name myapp \
  --memory=512m \
  --cpus=1.0 \
  --restart=unless-stopped \
  -e PYTHONUNBUFFERED=1 \
  myapp:latest

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

## References

- **Docker Docs**: https://docs.docker.com/
- **Dockerfile Best Practices**: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/