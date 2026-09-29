# Advanced Safety Patterns - Deep Dive

> This reference file is loaded on demand from ../SKILL.md.

## Thread-Safe State Management

```python
from PySide6.QtCore import QObject, QMutex, QMutexLocker, QAtomicPointer
from PySide6.QtCore import QThread, Signal
import threading

class ThreadSafeCounter:
    """Atomic counter for thread-safe increment."""
    
    def __init__(self, initial=0):
        self._value = QAtomicPointer(initial)
    
    def increment(self):
        """Atomic increment operation."""
        return QAtomicPointer.fetchAndAddRelaxed(self._value, 1)
    
    def get(self):
        """Atomic read."""
        return QAtomicPointer.load(self._value)
    
    def set(self, value):
        """Atomic write."""
        QAtomicPointer.store(self._value, value)

class SharedResource:
    """Advanced thread-safe resource."""
    
    def __init__(self):
        self._data = {}
        self._mutex = threading.Lock()  # Platform lock for cross-thread use
        self._ref_count = 0
        self._lock = QMutex()
    
    def acquire(self):
        """Thread-safe acquisition with timeout."""
        acquired = QMutex.tryLock(self._lock, 1000)  # 1 second timeout
        if not acquired:
            raise RuntimeError("Failed to acquire lock within timeout")
        self._ref_count += 1
    
    def release(self):
        """Thread-safe release."""
        QMutex.unlock(self._lock)
        self._ref_count -= 1
    
    def update(self, key, value):
        """Thread-safe update with atomicity."""
        locker = QMutexLocker(self._lock)
        # Critical section - only one thread here at a time
        self._data[key] = value
```

## Avoiding UI State Races

```python
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QObject, Signal, Slot
import threading

class UIStateManager:
    """Prevent UI state races using mutex guards."""
    
    def __init__(self):
        self._state_lock = threading.Lock()
        self._update_in_progress = False
    
    def safe_update_ui(self, value):
        """Ensure only one UI update at a time."""
        if threading.current_thread() is threading.main_thread():
            # Main thread - direct update
            self._apply_ui_update(value)
        else:
            # Worker thread - schedule update
            self.update_ui_slot(value)
    
    @Slot()
    def update_ui_slot(self, value):
        """Thread-safe slot for UI updates."""
        with self._state_lock:
            if self._update_in_progress:
                # Already updating - cancel and request again
                self._cancel_pending_update()
            self._update_in_progress = True
            try:
                # Apply UI update from main thread
                QApplication.instance().postEvent(
                    QApplication.instance(),
                    self._update_event(value)
                )
            finally:
                self._update_in_progress = False
    
    def _apply_ui_update(self, value):
        """Actual UI update - must be called from main thread."""
        self.status_label.setText(str(value))
    
    def _cancel_pending_update(self):
        """Cancel any pending UI updates."""
        self.status_label.setText("Updating...")
```

## Resource Exhaustion Prevention

```python
class ThreadPoolManager:
    """Configurable thread pool with resource limits."""
    
    def __init__(self, max_threads=4, max_concurrent=2):
        self.pool = QThreadPool()
        self.pool.setMaxThreadCount(max_threads)
        self.max_concurrent = max_concurrent
        self.active_count = 0
        self._lock = QMutex()
    
    def submit_safe(self, task):
        """Submit task only if under concurrency limit."""
        if self._should_proceed():
            self.pool.start(task)
        else:
            # Queue for later or reject
            print("Too many concurrent tasks")
    
    def _should_proceed(self):
        """Check if we can proceed with new task."""
        with QMutexLocker(self._lock):
            self.active_count += 1
            result = self.active_count < self.max_concurrent
            if not result:
                self.active_count -= 1
            return result
    
    def _cleanup_finished(self, task):
        """Called when task completes."""
        with QMutexLocker(self._lock):
            self.active_count -= 1

class LeakyResourceGuard:
    """Prevent resource leaks in long-running threads."""
    
    def __init__(self, max_duration=300, max_memory=100 * 1024 * 1024):  # 5 min, 100MB
        self.max_duration = max_duration
        self.max_memory = max_memory
        self._start_time = None
        self._memory_usage = 0
    
    def start(self):
        self._start_time = time.time()
        self._memory_usage = self._get_memory_usage()
    
    def check(self):
        """Check for resource exhaustion."""
        elapsed = time.time() - self._start_time
        current_memory = self._get_memory_usage()
        
        # Time limit
        if elapsed > self.max_duration:
            raise TimeoutError(f"Thread ran for {elapsed}s, exceeded {self.max_duration}s")
        
        # Memory limit
        memory_delta = current_memory - self._memory_usage
        if memory_delta > self.max_memory:
            raise MemoryError(f"Thread leaked {memory_delta} bytes")
    
    def _get_memory_usage(self):
        """Get approximate memory usage."""
        import resource
        return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
```