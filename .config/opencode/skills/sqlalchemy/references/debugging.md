# Loaded on demand from frameworks/sqlalchemy/SKILL.md — Common Issues & Debugging deep dive

## Common Issues & Debugging

### DetachedInstanceError

```python
# Problem: Accessing attributes after session closed
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
# print(user.name)  # DetachedInstanceError!

# Fix 1: Expire objects on commit = False
session = Session(engine, expire_on_commit=False)

# Fix 2: Access within session context
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
    name = user.name  # OK, still attached
```

### Lazy Loading Outside Sessions

```python
# Problem: Accessing relationships after session closed
with Session(engine) as session:
    user = session.scalar(select(User).limit(1))
# print(user.posts)  # Error! Relationship not loaded

# Fix: Use eager loading
stmt = select(User).options(selectinload(User.posts))
user = session.scalar(stmt)
print(user.posts)  # OK, already loaded
```

### N+1 Query Problem

```python
# BAD: N+1 queries (1 for users + N for each user's posts)
users = session.scalars(select(User)).all()
for user in users:
    print(len(user.posts))  # Triggers 1 query per user!

# GOOD: Single query with joined eager loading
from sqlalchemy.orm import joinedload
stmt = select(User).options(joinedload(User.posts))
users = session.scalars(stmt).unique().all()

# GOOD: Two queries with selective loading
from sqlalchemy.orm import selectinload
stmt = select(User).options(selectinload(User.posts))
users = session.scalars(stmt).all()
```

### Session Leak Detection

```python
# Enable session tracking for debugging
from sqlalchemy import event

@event.listens_for(Session, "after_commit")
def log_commit(session, context):
    logger.info(f"Session committed: {id(session)}")

@event.listens_for(Session, "after_rollback")
def log_rollback(session, context):
    logger.warning(f"Session rolled back: {id(session)}")

# Always use context managers to prevent leaks:
with Session(engine) as session:
    # work...
    session.commit()
# Guaranteed cleanup
```