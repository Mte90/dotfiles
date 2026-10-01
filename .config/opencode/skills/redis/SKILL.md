---
name: redis
description: Use when working with Redis - in-memory database, caching, pub/sub, sessions, rate limiting, RESP3, asyncio, Redis Stack
metadata:
  author: mte90
  version: 2.0.1
  tags:
    - redis
    - database
    - caching
    - pub-sub
    - sessions
    - rate-limiting
    - data-structures
    - nosql
    - resp3
    - asyncio
---

# Redis (redis-py v8.0)

Redis - in-memory data structure store, used as database, cache, and message broker.

**redis-py v8.0 changes:**
- Python 3.10+ required
- RESP3 is the default protocol (was RESP2 in 7.x)
- Async API: `redis.asyncio` module (not `.asyncio` property)

## Installation

```bash
pip install redis
```

## Basic Usage

### Synchronous Client

```python
import redis

# Default protocol is now RESP3
r = redis.Redis(host='localhost', port=6379, db=0)

# Basic commands
r.set('foo', 'bar')
value = r.get('foo')  # b'bar'

# Close connection
r.close()
```

### Async Client

```python
import redis.asyncio as redis

async def example():
    # Default protocol is RESP3
    r = redis.Redis(host='localhost', port=6379, db=0)
    
    await r.set('foo', 'bar')
    value = await r.get('foo')  # b'bar'
    
    # Close connection
    await r.aclose()
```

**Migration from v7.x:**
```python
# OLD (v7.x and earlier)
from redis import Redis
r = Redis()
client = r.asyncio  # Property

# NEW (v8.0+)
import redis.asyncio as redis
r = redis.Redis()
```

## Connection Pool

```python
# Create a connection pool
pool = redis.ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=50,
    decode_responses=True,
    socket_connect_timeout=5,
    socket_timeout=5,
    retry_on_timeout=True,
)

# Use pool with client
r = redis.Redis(connection_pool=pool)
```

### Connection Pool with Password

```python
pool = redis.ConnectionPool(
    host='localhost',
    port=6379,
    password='your_password',
    max_connections=100,
)
r = redis.Redis(connection_pool=pool)
```

## Core Commands

```python
# Strings
r.set('key', 'value', ex=300)
r.setnx('key', 'value')
r.mset({'key1': 'value1'})
r.get('key')
r.mget(['key1', 'key2'])
r.delete('key')
r.exists('key')
r.ttl('key')
r.expire('key', 300)

# Hashes
r.hset('user:1', mapping={'name': 'Alex', 'email': 'a@b.com'})
r.hget('user:1', 'name')
r.hgetall('user:1')
r.hexists('user:1', 'name')
r.hkeys('user:1')
r.hdel('user:1', 'name')

# Lists
r.lpush('mylist', 'item1', 'item2')
r.rpush('mylist', 'item3')
r.lpop('mylist')
r.rpop('mylist')
r.lrange('mylist', 0, -1)
r.llen('mylist')

# Sets
r.sadd('myset', 'item1', 'item2')
r.sismember('myset', 'item1')
r.smembers('myset')
r.srem('myset', 'item1')
r.sunion('set1', 'set2')
r.sinter('set1', 'set2')

# Sorted Sets
r.zadd('scores', {'player1': 100, 'player2': 200})
r.zrange('scores', 0, -1, withscores=True)
r.zrevrange('scores', 0, 9)
r.zrem('scores', 'player1')
r.zscore('scores', 'player1')
```

## RESP3 Protocol

RESP3 (Redis Serialization Protocol version 3) is the default in redis-py v8.0. It introduces push messages, better type support, and client-side caching.

### Negotiating RESP3

```python
# Explicitly request RESP3 (default in v8.0)
r = redis.Redis(protocol=3)

# Check negotiated protocol
info = r.info('server')
print(info['redis_version'])

# Verify protocol version
client_info = r.client_info()
# Look for 'proto' field in response
```

### RESP3 Features

**Push Messages:**
```python
# Enable push message handling
r = redis.Redis(protocol=3, push_response_callback=lambda msg: print(msg))

# Client-side caching with CLIENT TRACKING
r.execute_command('CLIENT TRACKING', 'ON', 'REDIRECT', r.connection_pool.get_connection('_').pid)
```

**New Commands/Options:**
```python
# GETDEL - atomic get and delete (RESP3-friendly pattern)
value = r.execute_command('GETDEL', 'key')

# EXPIRE with NX/XX/GT/LT options
r.expire('key', 300, nx=True)  # Only set if not exists
r.expire('key', 300, xx=True)  # Only set if exists

# OBJECT introspection
memory_usage = r.object_encoding('key')
idletime = r.object_idletime('key')

# COMMAND introspection
commands = r.command()
```

### Operational Caution

> **Proxy/Managed Service Downgrade:** A proxy (Twemproxy, Codis) or managed service in front of Redis may downgrade to RESP2 and silently remove RESP3 capabilities. Always verify the negotiated protocol before relying on RESP3-only behavior.

**Check before using RESP3 features:**
```python
def verify_resp3_support(client):
    """Verify RESP3 is actually available."""
    try:
        # Try a RESP3-specific command
        client.execute_command('HELLO', 3)
        return True
    except Exception:
        # Downgraded to RESP2
        return False
```

Source: [RESP3 Protocol Specification](https://github.com/antirez/redis-doc/blob/master/RESP3.md)

## Redis Stack Modules

### Redis Search

```python
r.ft().create_index((TextField('name'), NumericField('age'), TagField('tags')))
results = r.ft().search('@name:alex @age:[20 30]')
r.ft().dropindex()
```

### Redis JSON

```python
from redis.commands.json.path import Path

r.json().set('/user:1', Path.root_path(), {'name': 'Alex', 'age': 30})
r.json().get('/user:1')
r.json().get('/user:1', Path('$.name'))
r.json().merge('/user:1', Path.root_path(), {'age': 31})
r.json().del_('/user:1', Path('$.age'))
```

### Redis TimeSeries

```python
r.ts().create('sensor:1')
r.ts().add('sensor:1', '*', 25.3)
r.ts().range('sensor:1', 0, '*')
aggregated = r.ts().range('sensor:1', 0, '*', agg_type='avg', bucket_size=60000)
```

## Pipelines

```python
# Basic pipeline
pipe = r.pipeline()
pipe.set('key1', 'value1')
pipe.set('key2', 'value2')
pipe.get('key1')
results = pipe.execute()  # [True, True, b'value1']

# Watch for transactions
pipe = r.pipeline(True)
pipe.watch('mykey')
val = pipe.get('mykey')
pipe.multi()
pipe.set('mykey', val + 1)
pipe.execute()
```

## Rules That Prevent Incidents

These guidelines prevent specific failure modes in production.

### TTL Discipline Prevents Unbounded Key Growth

**Failure prevented:** Memory exhaustion from accumulating keys with no expiration.

Always set TTL on cache keys. Redis is an in-memory store; keys without TTL persist forever and accumulate.

```python
# BAD - key persists forever
r.set('user:session:123', session_data)

# GOOD - key expires after 1 hour
r.set('user:session:123', session_data, ex=3600)
```

### Never Use KEYS/SCAN Patterns on Large Keyspaces

**Failure prevented:** Single-threaded Redis blocking for seconds during KEYS * on millions of keys.

```python
# BAD - blocks Redis for seconds
keys = r.keys('user:*')

# GOOD - non-blocking scan
cursor = 0
while True:
    cursor, keys = r.scan(cursor, match='user:*', count=100)
    # Process keys
    if cursor == 0:
        break
```

### Pipeline vs Transaction vs Lua for Atomicity

**Failure prevented:** Race conditions when multiple operations must be atomic.

- **Pipeline:** Batch commands for single round-trip, not atomic
- **Transaction (WATCH/MULTI/EXEC):** Optimistic locking, fails if key changed
- **Lua script:** True atomicity, server-side execution

```python
# Pipeline - fast but NOT atomic
pipe = r.pipeline()
pipe.incr('counter')
pipe.set('flag', 'done')
pipe.execute()  # Another client can interleave

# Transaction - atomic if key unchanged
pipe = r.pipeline(True)
pipe.watch('counter')
pipe.multi()
pipe.incr('counter')
pipe.execute()  # Raises WatchError if counter changed

# Lua - truly atomic
script = """
local current = redis.call('INCR', KEYS[1])
redis.call('SET', KEYS[2], 'done')
return current
"""
r.eval(script, 2, 'counter', 'flag')
```

### Cache-Aside vs Write-Through Failure Behavior

**Failure prevented:** Stale data after cache invalidation.

- **Cache-aside:** App loads cache, misses, reads DB, writes cache. On write, invalidate cache. Risk: stale window between invalidate and next read.
- **Write-through:** App writes cache, cache writes DB. Risk: write latency doubles, cache write failure may lose data.

```python
# Cache-aside pattern
def get_user(user_id):
    key = f'user:{user_id}'
    user = r.get(key)
    if user is None:
        user = db.get_user(user_id)  # Slow path
        r.setex(key, 3600, user)  # Populate cache
    return user

# Invalidate on write
def update_user(user_id, data):
    db.update_user(user_id, data)
    r.delete(f'user:{user_id}')  # Invalidate, don't write
```

### Cache Stampede Prevention

**Failure prevented:** Thundering herd when popular key expires—thousands of requests hit DB simultaneously.

Use distributed lock or jittered TTL.

```python
# Lock-based refresh
import redis.lock

def get_user_safe(user_id):
    key = f'user:{user_id}'
    user = r.get(key)
    if user is None:
        lock = r.lock(f'lock:{key}', timeout=10)
        if lock.acquire(blocking=True):
            try:
                # Double-check after acquiring lock
                user = r.get(key)
                if user is None:
                    user = db.get_user(user_id)
                    r.setex(key, 3600, user)
            finally:
                lock.release()
        else:
            # Wait and retry
            time.sleep(0.1)
            user = r.get(key) or db.get_user(user_id)
    return user

# Jittered TTL approach
import random
ttl = 3600 + random.randint(-300, 300)  # ±5 min jitter
r.setex(key, ttl, user)
```

### Never Cache Per-Request Volatile Data

**Failure prevented:** Cross-request data leakage, memory waste from unique keys.

```python
# BAD - each request creates unique key
cache.set(f'token:{request_id}', token, timeout=300)

# GOOD - session-scoped data stays in memory/session store
request.session['token'] = token
```

## Production Failure Modes

Understanding these failure modes helps diagnose production issues.

### Connection Exhaustion Under Burst

**Symptom:** `Connection refused` or timeout errors during traffic spikes.

Redis uses a single thread for command processing. Too many concurrent connections exhaust file descriptors and cause connection failures.

**Fix:** Use a connection pooler or enforce bounded concurrency.

```python
# Bounded connection pool
pool = redis.ConnectionPool(
    max_connections=50,  # Cap connections
    socket_connect_timeout=5,
    socket_timeout=5,
    retry_on_timeout=True,
)
r = redis.Redis(connection_pool=pool)
```

### maxmemory Eviction Policy Silently Dropping Keys

**Symptom:** Cache returns missing keys despite recent writes; data appears to "disappear".

When Redis hits `maxmemory`, it evicts keys based on the configured policy. The wrong policy turns a cache into a source of data loss.

**Check eviction policy:**
```bash
redis-cli CONFIG GET maxmemory-policy
```

**Common policies:**
- `noeviction`: Returns error when memory full (default for persistence)
- `allkeys-lru`: Evict least recently used keys (good for cache)
- `volatile-lru`: Evict LRU keys with TTL set (good for mixed workloads)
- `allkeys-lfu`: Evict least frequently used keys (Redis 4.0+)

```python
# Set appropriate eviction policy
r.config_set('maxmemory-policy', 'allkeys-lru')
```

### Replication Lag Causing Stale Read After Write

**Symptom:** Write succeeds, immediate read from replica returns old value.

In replicated setups, writes go to primary, reads may hit replica. Replication lag causes stale reads.

**Fix:** Read from primary after writes, or use `WAIT` to confirm replication.

```python
# Wait for replica acknowledgment
result = r.set('key', 'value')
replicas_acked = r.wait(1, timeout=1000)  # Wait for 1 replica
if replicas_acked == 0:
    log.warning("Replication lag detected")
```

### Blocking Commands Freezing Single-Threaded Server

**Symptom:** All clients experience latency spike; Redis appears frozen.

Redis is single-threaded. Blocking commands like `KEYS`, `SORT`, `HGETALL` on large hashes freeze the server.

**Check slowlog:**
```bash
redis-cli SLOWLOG GET 10
```

```python
# BAD - blocks server
all_keys = r.keys('*')

# GOOD - use SCAN
cursor = 0
while True:
    cursor, keys = r.scan(cursor, count=100)
    if cursor == 0:
        break
```

### Slowlog as First Diagnostic for Latency

**Symptom:** Gradual latency increase; occasional spikes.

The slowlog captures commands exceeding a threshold. Inspect it first when diagnosing latency.

```python
# Set slowlog threshold (microseconds)
r.config_set('slowlog-log-slower-than', 10000)  # 10ms

# Get slow queries
slow_queries = r.slowlog_get(10)
for query in slow_queries:
    print(f"Command: {query['command']}")
    print(f"Duration: {query['duration']}µs")
    print(f"Timestamp: {query['timestamp']}")
```

## When Not to Use Redis

Not every workload benefits from Redis. Know when to choose alternatives.

### Relational Database Is Enough

Many caching use cases don't need Redis. If your access patterns are simple and data volume fits in database memory, use the database cache.

**Use database instead of Redis when:**
- Query patterns are straightforward (primary key lookups, indexed searches)
- Data consistency is critical over speed
- You already have connection pooling and query caching in place

### Job Queues Belong to a Dedicated Broker

Redis can power job queues, but dedicated brokers (RabbitMQ, SQS, Bull) provide:
- Message acknowledgment and retry
- Dead letter queues
- Priority queues
- Better visibility and monitoring

**Use a dedicated broker when:**
- Jobs must not be lost
- Complex routing or priority is needed
- You need visibility into queue depth and processing

### Caching Pages Nobody Requests

Caching costs memory. If a page is rarely accessed, caching it wastes memory and adds complexity.

**Cache only when:**
- Hit rate is high (>80%)
- Computation/cache miss is expensive
- Data is read-heavy, write-light

### Multi-Region Writes Need Different Consistency

Redis is primarily single-primary. Multi-region active-active setups require different consistency models.

**Consider alternatives when:**
- You need true multi-region writes with low latency
- Strong consistency across regions is required
- Conflict resolution is complex

## Django Integration

Django-specific patterns (django-redis cache backend, invalidation on model save, per-user rate limiting, Celery broker, Channels) live in `references/django-integration.md`.

## Deep Dives

Load these reference files on demand for specific use cases:

- `references/django-integration.md` — When working with Django projects (cache backend, invalidation, rate limiting, Celery, Channels)

## CLI Operations

```bash
# Connect
redis-cli

# Check keys (use with caution)
KEYS *

# Delete by pattern (use with caution)
SCAN 0 MATCH user:* COUNT 1000 | xargs redis-cli DEL

# Clear current database
FLUSHDB

# Monitor commands
MONITOR

# Check slowlog
SLOWLOG GET 10

# Check eviction policy
CONFIG GET maxmemory-policy
```

## References
- [redis-py Official Documentation](https://redis.readthedocs.io/)
- [redis-py v8.0 Release Notes](https://github.com/redis/redis-py/releases)
- [Redis Stack Documentation](https://redis.io/docs/stack/)
- [RESP3 Protocol Specification](https://github.com/antirez/redis-doc/blob/master/RESP3.md)
