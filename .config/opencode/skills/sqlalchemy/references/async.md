# Loaded on demand from ../SKILL.md - Async SQLAlchemy and FastAPI integration

## Async SQLAlchemy

### Async Models and Session

```python
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)
from sqlalchemy.orm import Mapped, mapped_column

# Async engine
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")

# Async session factory
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Async context manager
async with async_session() as session:
    async with session.begin():
        result = await session.execute(select(User))
        users = result.scalars().all()
```

### Async Queries

```python
from sqlalchemy import select

async def get_user(user_id: int) -> Optional[User]:
    async with async_session() as session:
        result = await session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

async def get_users_paginated(page: int, per_page: int) -> List[User]:
    async with async_session() as session:
        stmt = (
            select(User)
            .order_by(User.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
        )
        result = await session.execute(stmt)
        return result.scalars().all()

async def create_user(username: str, email: str) -> User:
    async with async_session() as session:
        async with session.begin():
            user = User(username=username, email=email)
            session.add(user)
            await session.flush()
            await session.refresh(user)
            return user
```

### Async with FastAPI

```python
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

app = FastAPI()

async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/users")
async def create_user(
    username: str,
    email: str,
    db: AsyncSession = Depends(get_db)
):
    user = User(username=username, email=email)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
```