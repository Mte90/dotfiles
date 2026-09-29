# Qt Concurrent - Deep Dive

> This reference file is loaded on demand from ../SKILL.md.

## QtConcurrent for Map/Filter/Reduce

For high-level parallel operations on collections without managing threads manually:

```python
from PySide6.QtConcurrent import QtConcurrent
from PySide6.QtCore import QFutureWatcher, QObject, Signal

class ConcurrentProcessor(QObject):
    """Process data using QtConcurrent high-level API."""
    finished = Signal(list)
    progress = Signal(int)
    
    def map_process(self, items):
        """Map operation - transform each item."""
        def process_item(item):
            # Heavy computation here
            return item.upper()
        
        future = QtConcurrent.mapped(items, process_item)
        
        watcher = QFutureWatcher()
        watcher.finished.connect(lambda: self.on_done(future))
        watcher.setFuture(future)
    
    def filter_process(self, items, predicate):
        """Filter operation - keep matching items."""
        future = QtConcurrent.filtered(items, predicate)
        
        watcher = QFutureWatcher()
        watcher.finished.connect(lambda: self.on_done(future))
        watcher.setFuture(future)
    
    def reduce_process(self, items):
        """Reduce operation - combine all items."""
        def reducer(accumulator, item):
            accumulator.append(item.upper())
            return accumulator
        
        future = QtConcurrent.reduced(items, reducer)
        
        watcher = QFutureWatcher()
        watcher.finished.connect(lambda: self.on_done(future))
        watcher.setFuture(future)
    
    def on_done(self, future):
        results = future.result()
        self.finished.emit(list(results))
```

## QtConcurrent with Progress Tracking

```python
from PySide6.QtConcurrent import QtConcurrent
from PySide6.QtCore import QFutureWatcher, QObject, Signal

class ProgressAwareProcessor(QObject):
    """Track progress of QtConcurrent operations."""
    progress = Signal(int)
    finished = Signal(object)
    
    def process_with_progress(self, items):
        """Process items with progress reporting."""
        def process_item(item):
            # Heavy work
            return item * 2
        
        future = QtConcurrent.mapped(items, process_item)
        
        self.watcher = QFutureWatcher()
        self.watcher.progressChanged.connect(self.progress.emit)
        self.watcher.finished.connect(lambda: self.on_finished(future))
        self.watcher.setFuture(future)
    
    def on_finished(self, future):
        results = future.result()
        self.finished.emit({"results": results, "count": len(results)})
```

## QtConcurrent Run - Simple Fire-and-Forget

For simple background tasks without collection operations:

```python
from PySide6.QtConcurrent import QtConcurrent
from PySide6.QtCore import QObject, Signal

class SimpleBackgroundWorker(QObject):
    """Simple background processing with QtConcurrent.run()."""
    finished = Signal(object)
    error = Signal(str)
    
    def run_background_task(self, data):
        """Run a simple background task."""
        def background_work():
            # Heavy computation
            import time
            time.sleep(1)
            return {"status": "done", "data": data}
        
        future = QtConcurrent.run(background_work)
        
        watcher = QFutureWatcher()
        watcher.finished.connect(lambda: self.on_complete(future))
        watcher.setFuture(future)
    
    def on_complete(self, future):
        try:
            result = future.result()
            self.finished.emit(result)
        except Exception as e:
            self.error.emit(str(e))
```

## When to Use QtConcurrent vs QThread

| Use Case | Recommended Approach |
|----------|---------------------|
| Map/filter/reduce on collections | **QtConcurrent** - high-level API |
| Single long-running task | **QThread + moveToThread** |
| Parallel independent tasks | **QThreadPool + QRunnable** |
| Need fine-grained thread control | **QThread subclass** |
| Periodic polling | **QTimer** |
| Simple background work | **QtConcurrent.run()** |

**QtConcurrent advantages:**
- No manual thread management
- Automatic thread pool usage
- Built-in progress tracking
- Clean API for collection operations

**QtConcurrent limitations:**
- Less control over thread lifecycle
- Cannot easily cancel mid-execution
- Not suitable for interactive long-running tasks