---
name: sqlite
description: "SQLite - embedded database, SQL queries, schema design, Python integration, optimization"
metadata:
  author: mte90
  version: 1.0.0
  tags:
    - sqlite
    - database
    - sql
    - embedded
    - python
    - db-api
---

# SQLite

SQLite - self-contained, serverless, zero-configuration SQL database engine.

## Overview

SQLite is an embedded relational database. The entire database is stored in a single cross-platform disk file. No server process needed.

- **Serverless** - No separate server process
- **Zero config** - No installation or setup
- **Single file** - Entire database in one `.db` file
- **ACID** - Full transactional support
- **Cross-platform** - Works everywhere

> See [Slicker.me SQLite Features](https://slicker.me/sqlite/features.htm) for a comprehensive feature overview.

---

## Python Integration

### Basic Usage

```python
import sqlite3

# Connect (creates file if not exists)
conn = sqlite3.connect('myapp.db')

# Use as context manager (auto-commits)
with sqlite3.connect('myapp.db') as conn:
    conn.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)")
    conn.execute("INSERT INTO users (name, email) VALUES (?, ?)", ("Alice", "alice@example.com"))
    conn.commit()

# In-memory database
conn = sqlite3.connect(':memory:')
```

### Row Factory

```python
# Access columns by name
conn = sqlite3.connect('myapp.db')
conn.row_factory = sqlite3.Row

cursor = conn.execute("SELECT * FROM users")
for row in cursor:
    print(row['name'], row['email'])

# Or use dict factory
def dict_factory(cursor, row):
    return {col[0]: row[i] for i, col in enumerate(cursor.description)}

conn.row_factory = dict_factory
```

### CRUD Operations

```python
import sqlite3

conn = sqlite3.connect('app.db')
conn.row_factory = sqlite3.Row

# Create
conn.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT,
        in_stock INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

# Insert
conn.execute("INSERT INTO products (name, price, category) VALUES (?, ?, ?)",
             ("Widget", 9.99, "gadgets"))

# Bulk insert
products = [("A", 1.0, "cat1"), ("B", 2.0, "cat2"), ("C", 3.0, "cat1")]
conn.executemany("INSERT INTO products (name, price, category) VALUES (?, ?, ?)", products)
conn.commit()

# Read
cursor = conn.execute("SELECT * FROM products WHERE price > ?", (2.0,))
for row in cursor:
    print(dict(row))

# Update
conn.execute("UPDATE products SET price = ? WHERE name = ?", (12.99, "Widget"))
conn.commit()

# Delete
conn.execute("DELETE FROM products WHERE id = ?", (1,))
conn.commit()

conn.close()
```

---

## Schema Design

### Data Types

SQLite uses dynamic typing with storage classes:
- **NULL** - Null value
- **INTEGER** - Signed integer (1-8 bytes)
- **REAL** - Floating point (8-byte IEEE)
- **TEXT** - UTF-8, UTF-16BE, or UTF-16LE string
- **BLOB** - Binary data

### Table Creation

```sql
-- Basic table
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- With foreign key
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Enable foreign keys (required in SQLite)
PRAGMA foreign_keys = ON;

-- Index
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);

-- Unique constraint
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- Composite index
CREATE INDEX idx_products_cat_price ON products(category, price);
```

### Alter Table

```sql
-- SQLite supports limited ALTER TABLE
ALTER TABLE users ADD COLUMN avatar TEXT;
ALTER TABLE users RENAME COLUMN username TO handle;
ALTER TABLE users RENAME TO accounts;

-- For complex changes, recreate:
BEGIN TRANSACTION;
CREATE TABLE users_new (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE
);
INSERT INTO users_new SELECT id, name, email FROM users;
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;
COMMIT;
```

---

## Transactions

```python
# Manual transaction
conn = sqlite3.connect('app.db')
conn.execute("PRAGMA foreign_keys = ON")

try:
    conn.execute("BEGIN")
    conn.execute("INSERT INTO orders (user_id, total) VALUES (?, ?)", (1, 99.99))
    conn.execute("UPDATE users SET is_active = 1 WHERE id = ?", (1,))
    conn.commit()
except Exception as e:
    conn.rollback()
    raise

# Context manager (auto-commit or rollback)
with conn:
    conn.execute("INSERT INTO users (name) VALUES (?)", ("Bob",))
    # Auto-commits on success, auto-rollback on exception
```

---

## Advanced Queries

### Joins

```sql
-- Inner join
SELECT o.id, u.username, o.total, o.status
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'completed';

-- Left join
SELECT u.username, COUNT(o.id) as order_count, COALESCE(SUM(o.total), 0) as total_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id
HAVING order_count > 0;

-- Subquery
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- Common Table Expression (CTE)
WITH active_users AS (
    SELECT id, username FROM users WHERE is_active = 1
)
SELECT au.username, COUNT(o.id) as orders
FROM active_users au
LEFT JOIN orders o ON au.id = o.user_id
GROUP BY au.id;
```

### Window Functions

```sql
-- Row number
SELECT name, price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as rank
FROM products;

-- Partitioned aggregation
SELECT name, category, price,
    RANK() OVER (PARTITION BY category ORDER BY price DESC) as category_rank,
    AVG(price) OVER (PARTITION BY category) as avg_category_price
FROM products;

-- Running total
SELECT id, total,
    SUM(total) OVER (ORDER BY id) as running_total
FROM orders;
```

### Upsert (INSERT OR REPLACE)

```sql
-- Insert or replace
INSERT OR REPLACE INTO users (id, name, email)
VALUES (1, 'Alice', 'alice@new.com');

-- Insert or ignore (skip if conflict)
INSERT OR IGNORE INTO users (id, name, email)
VALUES (1, 'Alice', 'alice@example.com');

-- UPSERT with DO UPDATE (SQLite 3.24+)
INSERT INTO users (username, email)
VALUES ('bob', 'bob@example.com')
ON CONFLICT(username) DO UPDATE SET
    email = excluded.email;
```

---

## Full-Text Search (FTS5)

```sql
-- Create FTS table
CREATE VIRTUAL TABLE articles_fts USING fts5(title, body, content='articles', content_rowid='id');

-- Populate
INSERT INTO articles_fts (rowid, title, body) SELECT id, title, body FROM articles;

-- Search
SELECT * FROM articles_fts WHERE articles_fts MATCH 'sqlite AND python';
SELECT * FROM articles_fts WHERE articles_fts MATCH 'sqlite OR database';
SELECT * FROM articles_fts WHERE articles_fts MATCH '"full text search"';

-- Ranked results
SELECT rank, * FROM articles_fts WHERE articles_fts MATCH 'sqlite' ORDER BY rank;

-- Keep FTS in sync with triggers
CREATE TRIGGER articles_ai AFTER INSERT ON articles BEGIN
    INSERT INTO articles_fts (rowid, title, body) VALUES (new.id, new.title, new.body);
END;

CREATE TRIGGER articles_ad AFTER DELETE ON articles BEGIN
    INSERT INTO articles_fts (articles_fts, rowid, title, body) VALUES ('delete', old.id, old.title, old.body);
END;
```

---

## JSON Support

```sql
-- Store JSON in TEXT column
CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    data TEXT
);

-- Extract values
SELECT json_extract(data, '$.name') FROM events;
SELECT json_extract(data, '$.tags[0]') FROM events;

-- Insert JSON
INSERT INTO events (data) VALUES (json('{"name": "click", "tags": ["ui", "btn"]}'));

-- JSON functions
SELECT json_type(data) FROM events;          -- 'object'
SELECT json_array_length(data, '$.tags') FROM events;  -- 2
SELECT json_insert(data, '$.count', 1) FROM events;
SELECT json_set(data, '$.count', 42) FROM events;
```

---

## Optimization

### PRAGMA Settings

```python
conn = sqlite3.connect('app.db')

# Performance
conn.execute("PRAGMA journal_mode = WAL")         # Write-Ahead Logging
conn.execute("PRAGMA synchronous = NORMAL")        # Balance safety/speed
conn.execute("PRAGMA cache_size = -64000")          # 64MB cache
conn.execute("PRAGMA temp_store = MEMORY")          # Temp tables in memory
conn.execute("PRAGMA mmap_size = 268435456")        # 256MB memory map

# Safety
conn.execute("PRAGMA foreign_keys = ON")            # Enable FK constraints
conn.execute("PRAGMA busy_timeout = 5000")          # Wait 5s on lock
```

### Query Analysis

```sql
-- Explain query plan
EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = 'test@example.com';

-- Check indexes
SELECT * FROM pragma_index_list('users');

-- Table info
PRAGMA table_info(users);
PRAGMA index_list(users);
PRAGMA index_info(idx_users_email);
```

### Statistics with ANALYZE

The query planner picks indexes based on table statistics. Without them it can
choose catastrophically bad plans — an FTS5 query on a few thousand rows can go
from 5s to 0.05s after a single `ANALYZE`.

```sql
-- Gather statistics for the query planner
ANALYZE;

-- Re-run after bulk loads, schema changes, or significant data drift
-- Inspect stored stats:
SELECT * FROM sqlite_stat1;
SELECT * FROM sqlite_stat4;  -- if SQLITE_ENABLE_STAT4
```

Without `ANALYZE`, a 4000-row FTS5 table can pick an accidentally-quadratic
plan. Run it once after load, then schedule periodically.

### Bulk Operations

```python
# Fast bulk insert
conn.execute("PRAGMA synchronous = OFF")
conn.execute("PRAGMA journal_mode = MEMORY")

conn.executemany(
    "INSERT INTO large_table (col1, col2) VALUES (?, ?)",
    data  # list of tuples
)
conn.commit()

conn.execute("PRAGMA synchronous = NORMAL")
conn.execute("PRAGMA journal_mode = WAL")
```

---

## Backups

### Online Backup (Python API)

```python
import sqlite3

def backup_database(src_path, dst_path):
    src = sqlite3.connect(src_path)
    dst = sqlite3.connect(dst_path)
    src.backup(dst)
    dst.close()
    src.close()
```

### VACUUM INTO (snapshot without holding a long lock)

`VACUUM INTO` produces a clean, defragmented copy in one statement. Pair with
`gzip` and an off-site uploader (restic, rsync, S3 CLI) for nightly snapshots.

```bash
sqlite3 /data/app.db "VACUUM INTO '/tmp/app.sqlite'"
gzip /tmp/app.sqlite
restic -r s3://bucket/backup backup /tmp/app.sqlite.gz
restic -r s3://bucket/backup forget -l 1 -H 6 -d 2 -w 2 -m 2 -y 2
restic -r s3://bucket/backup prune
```

`VACUUM INTO` reads the whole database, so on large DBs it can exceed memory
or time budgets under a busy writer — batch outside peak traffic.

### Litestream (streaming replication)

[Litestream](https://litestream.io/) continuously streams the WAL to S3-compatible
storage, giving near-zero-RPO recovery without full-database snapshots.

```yaml
# litestream.yml
dbs:
  - path: /data/app.db
    replicas:
      - url: s3://bucket/app
        retention: 400h
```

```bash
litestream replicate -config litestream.yml
# Restore:
# litestream restore -o /data/app.db s3://bucket/app
```

Prefer Litestream over scheduled `VACUUM INTO` when the database changes often —
incremental WAL shipping avoids the OOM risk of snapshotting a large DB.

### Verify backups

A backup that was never restored is a myth. Test restore on a throwaway instance
and `PRAGMA integrity_check;` before trusting it.

---

## Common Patterns

### Connection Pool (Thread-safe)

```python
import sqlite3
import threading
from contextlib import contextmanager

class SQLitePool:
    def __init__(self, db_path, max_connections=5):
        self.db_path = db_path
        self._local = threading.local()
        
    def get_connection(self):
        if not hasattr(self._local, 'conn'):
            self._local.conn = sqlite3.connect(self.db_path)
            self._local.conn.row_factory = sqlite3.Row
            self._local.conn.execute("PRAGMA journal_mode = WAL")
            self._local.conn.execute("PRAGMA foreign_keys = ON")
        return self._local.conn
    
    @contextmanager
    def cursor(self):
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            yield cursor
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            cursor.close()
```

### Split Tables Across Multiple Files

When tables don't need to join, put them in separate `.db` files. Each file
gets its own writer lock, so independent workloads stop contending.

```python
import sqlite3

users = sqlite3.connect("users.db")
events = sqlite3.connect("events.db")
# users.db and events.db have independent write locks,
# independent WAL files, and independent backups.
```

ATTACH can still cross-query when needed:

```sql
ATTACH 'events.db' AS events;
SELECT u.name, e.title FROM users u JOIN events.events e ON e.user_id = u.id;
```

Trade-off: no cross-database foreign keys, and transactions are not atomic
across files. Only split when the tables are genuinely independent.

### Migration Helper

```python
import sqlite3

MIGRATIONS = {
    1: """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL
        );
    """,
    2: """
        CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            total REAL NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE INDEX idx_orders_user ON orders(user_id);
    """,
}

def run_migrations(db_path):
    conn = sqlite3.connect(db_path)
    conn.execute("CREATE TABLE IF NOT EXISTS _migrations (version INTEGER PRIMARY KEY)")
    
    current = conn.execute("SELECT MAX(version) FROM _migrations").fetchone()[0] or 0
    
    for version, sql in sorted(MIGRATIONS.items()):
        if version > current:
            conn.executescript(sql)
            conn.execute("INSERT INTO _migrations (version) VALUES (?)", (version,))
            conn.commit()
            print(f"Migration {version} applied")
    
    conn.close()
```

---

## CLI Commands

```bash
# Open database
sqlite3 myapp.db

# Execute SQL
sqlite3 myapp.db "SELECT * FROM users;"

# Import CSV
sqlite3 myapp.db -csv -header "SELECT * FROM users;" > output.csv

# Export schema
sqlite3 myapp.db ".schema"

# Dump database
sqlite3 myapp.db ".dump" > backup.sql

# Restore from dump
sqlite3 new.db < backup.sql

# List tables
sqlite3 myapp.db ".tables"

# Describe table
sqlite3 myapp.db ".schema users"
```

## Best Practices

### Essential PRAGMA Settings

```python
import sqlite3

conn = sqlite3.connect('app.db')

# Performance
conn.execute("PRAGMA journal_mode = WAL")      # Write-Ahead Logging
conn.execute("PRAGMA synchronous = NORMAL")    # Balance safety/speed
conn.execute("PRAGMA cache_size = -64000")      # 64MB cache
conn.execute("PRAGMA temp_store = MEMORY")     # Temp tables in memory
conn.execute("PRAGMA mmap_size = 268435456")    # 256MB memory map

# Safety
conn.execute("PRAGMA foreign_keys = ON")       # Enforce FK constraints
conn.execute("PRAGMA busy_timeout = 5000")      # Wait 5s on lock

# Always enable WAL mode for concurrent access
# Benefits: better concurrency, atomic writes, faster reads
```

### Connection Management

```python
# Use context manager (auto-commits/rollbacks)
with sqlite3.connect('app.db') as conn:
    conn.execute("INSERT INTO users VALUES (?, ?)", (name, email))
    # Auto-commits, auto-closes

# Row factory for column access
conn.row_factory = sqlite3.Row  # Access by name: row['column']

# Never leave connections open
# For web apps: create per-request, close after response
```

### Performance Tips

```python
# Use executemany for bulk inserts
data = [(f"user{i}", f"email{i}@test.com") for i in range(1000)]
conn.executemany("INSERT INTO users (name, email) VALUES (?, ?)", data)

# Disable sync for bulk loads
conn.execute("PRAGMA synchronous = OFF")
# ... bulk insert ...
conn.execute("PRAGMA synchronous = NORMAL")

# Create indexes after data load (faster)
# CREATE INDEX IF NOT EXISTS idx_user_email ON users(email);

# Use EXPLAIN QUERY PLAN to analyze queries
```

### Thread Safety

```python
# Each thread needs its own connection
# ❌ BAD: Shared connection
# conn = sqlite3.connect('app.db')  # Don't share across threads

# ✅ GOOD: Thread-local connections
import threading
thread_local = threading.local()

def get_db():
    if not hasattr(thread_local, 'conn'):
        thread_local.conn = sqlite3.connect('app.db')
    return thread_local.conn
```

### Key Patterns

```python
# Use parameterized queries (prevent SQL injection)
# ✅ GOOD
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# ❌ BAD - vulnerable to SQL injection
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# Use INTEGER PRIMARY KEY for auto-increment
# Don't use TEXT PRIMARY KEY (slower)

# Add indexes on foreign keys and WHERE columns
# CREATE INDEX idx_orders_user ON orders(user_id);
```

### Do:

- Enable WAL mode for concurrent access
- Always use parameterized queries
- Set busy_timeout for handling locks
- Use context managers for connections

### Don't:

- Use strings for PRIMARY KEY when INTEGER suffices
- Run ANALYZE after every write (do it periodically)
- Use database file on network drives (slow)
- Forget to enable foreign keys (they're off by default)

---

## References

- **SQLite Docs**: https://www.sqlite.org/docs.html
- **SQLite Python**: https://docs.python.org/3/library/sqlite3.html
- **SQL As Understood By SQLite**: https://www.sqlite.org/lang.html
- **SQLite WAL**: https://www.sqlite.org/wal.html
- **SQLite Limits**: https://www.sqlite.org/limits.html
- **Corruption FAQ**: https://www.sqlite.org/lockingv3.html
- **OpenCode Issue #21215**: concurrent sessions crash with SQLITE_BUSY
- **OpenCode Issue #21790**: sessions lost due to failed migration
- **jvns.ca – Learning about running SQLite**: https://jvns.ca/blog/2026/07/17/learning-about-running-sqlite/

---

## Concurrent Access & Locking Issues

### The Problem: WAL Mode and Concurrency

WAL (Write-Ahead Logging) allows concurrent readers but **only ONE writer at a time**:

```python
# Problem: with busy_timeout=0, writers fail immediately
# SQLiteError: database is locked

# Solution: set appropriate busy_timeout
conn.execute("PRAGMA busy_timeout = 5000")  # 5 seconds retry
```

### Best Practices for Concurrent Access

```python
import sqlite3

def get_connection(db_path):
    conn = sqlite3.connect(db_path)

    # Performance
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA cache_size = -64000")

    # CRITICAL for concurrency
    conn.execute("PRAGMA busy_timeout = 5000")

    # Safety
    conn.execute("PRAGMA foreign_keys = ON")

    return conn
```

### Long-Running Writes and Batch Deletes

WAL allows one writer at a time. A `DELETE FROM big_table WHERE ...` that runs
longer than `busy_timeout` blocks every other writer and can crash workers when
they hit the 5s default.

```python
# BAD: one big delete holds the write lock for seconds
conn.execute("DELETE FROM completed_tasks WHERE created_at < ?", (cutoff,))

# GOOD: delete in small batches so each transaction is sub-second
while True:
    cur = conn.execute(
        "DELETE FROM completed_tasks WHERE rowid IN ("
        "  SELECT rowid FROM completed_tasks WHERE created_at < ? LIMIT 1000"
        ")",
        (cutoff,),
    )
    conn.commit()
    if cur.rowcount == 0:
        break
```

For large maintenance, prefer scheduled maintenance windows over live batches.

### Isolation for Multiple Instances

To avoid contention in applications with multiple instances:

```python
import os

# Use XDG_DATA_HOME isolation for separate sessions
# Example: opencode run with multiple workers
os.environ['XDG_DATA_HOME'] = f'/tmp/opencode-{os.getpid()}'
# Each worker has its own DB
```
---

## Database Corruption Recovery

### Signs of Corruption

```
SQLiteError: database disk image is malformed
SQLiteError: file is not a database
SQLITE_CANTOPEN: unable to open database file
```

### Recovery Procedure

```bash
# 1. Make backup
cp corrupted.db corrupted.db.bak

# 2. Validate the database
sqlite3 corrupted.db "PRAGMA integrity_check;"
# Output: ok (if all good) or list of errors

# 3. Try to recover data
sqlite3 corrupted.db ".recover" | sqlite3 new.db

# 4. If it doesn't work, dump and rebuild
sqlite3 corrupted.db ".dump" 2>/dev/null | sqlite3 rebuilt.db
```

### Corruption Prevention

```python
# 1. Always use WAL mode (not DELETE) for consistency
conn.execute("PRAGMA journal_mode = WAL")

# 2. Clean close - don't kill process
# Use context manager
with sqlite3.connect('app.db') as conn:
    # work
# Auto-close guaranteed

# 3. Regular backups
def backup_db(src, dst):
    src_conn = sqlite3.connect(src)
    dst_conn = sqlite3.connect(dst)
    src_conn.backup(dst_conn)
    dst_conn.close()
    src_conn.close()
```

---

## Large Database Maintenance

### Size Monitoring

```python
import os

def get_db_size(db_path):
    """Returns size in MB"""
    return os.path.getsize(db_path) / (1024 * 1024)

# Example: real OpenCode database
# Size: 1214 MB
# Sessions: 1542
# Messages: 61873
# Parts: 253442

db_size = get_db_size('app.db')
print(f"Database size: {db_size:.1f} MB")

if db_size > 1000:
    print("WARNING: Database > 1GB, consider maintenance")
```

### Periodic Maintenance

```python
def maintain_database(conn):
    """Call periodically or after many writes"""

    # VACUUM: rebuild and compact the database
    # Reduces size, rebuilds indexes
    conn.execute("VACUUM")

    # ANALYZE: update statistics for query planner
    # Useful after many INSERT/UPDATE/DELETE
    conn.execute("ANALYZE")

    # Check integrity
    result = conn.execute("PRAGMA integrity_check").fetchone()
    if result[0] != 'ok':
        print(f"WARNING: {result[0]}")

# Schedule: weekly or after N write operations
# NOTE: VACUUM doesn't work in transaction
```

### Statistics Queries

```sql
-- Basic statistics
SELECT 'Sessions:' as label, COUNT(*) FROM session;
SELECT 'Messages:' as label, COUNT(*) FROM message;
SELECT 'Parts:' as label, COUNT(*) FROM part;

-- Old sessions (>30 days)
SELECT COUNT(*) FROM session
WHERE time_updated < (strftime('%s', 'now') - 30*86400)*1000;

-- Orphan records (without relationships)
SELECT COUNT(*) FROM message m
LEFT JOIN session s ON m.session_id = s.id
WHERE s.id IS NULL;

SELECT COUNT(*) FROM part p
LEFT JOIN message m ON p.message_id = m.id
WHERE m.id IS NULL;

-- Todo by status
SELECT status, COUNT(*) FROM todo GROUP BY status;
```
