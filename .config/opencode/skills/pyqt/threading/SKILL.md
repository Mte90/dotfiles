---
name: pyqt-threading
description: "PyQt/PySide6 threading and concurrency - QThread, QThreadPool, QTimer, thread safety, concurrent patterns"
metadata:
  author: mte90
  version: 1.0.0
  tags:
    - python
    - qt
    - pyqt
    - pyside
    - threading
    - concurrency
    - async
    - qthread
---

# PyQt Threading - Concurrency and Thread Safety

Comprehensive guide to threading in PyQt applications.

## Thread Safety Rules

**CRITICAL**: Qt/PyQt is NOT thread-safe for UI operations. You MUST follow these rules:

1. **Never access widgets from worker threads** - Only the main thread can modify UI
2. **Use signals for cross-thread communication** - Emit signals from worker, connect to slots in main thread
3. **Use Qt.QueuedConnection for thread-safe signal delivery** - AutoConnection handles this automatically
4. **Never block the main thread** - Long operations will freeze the UI

```python
# ❌ WRONG: Direct UI access from thread
class BadWorker(QThread):
    def run(self):
        # This will crash or cause undefined behavior!
        self.label.setText("Done")

# ✅ CORRECT: Use signals
class GoodWorker(QThread):
    finished = Signal(str)
    
    def run(self):
        result = self.process_data()
        self.finished.emit(result)  # Signal emitted, UI updated in main thread
```

## QThread with Worker Object (Recommended Pattern)

The most flexible pattern separates the worker logic from thread lifecycle:

```python
from PySide6.QtCore import QThread, Signal, QObject, Slot

class Worker(QObject):
    """Worker object that does the actual work."""
    finished = Signal(object)
    progress = Signal(int)
    error = Signal(str)
    
    def __init__(self, data):
        super().__init__()
        self.data = data
        self._is_cancelled = False
    
    @Slot()
    def process(self):
        """Main processing method called from thread."""
        try:
            for i, item in enumerate(self.data):
                if self._is_cancelled:
                    return
                
                # Simulate heavy work
                result = self.process_item(item)
                self.progress.emit(int((i + 1) / len(self.data) * 100))
            
            self.finished.emit({"status": "success", "count": len(self.data)})
        except Exception as e:
            self.error.emit(str(e))
    
    def cancel(self):
        self._is_cancelled = True
    
    def process_item(self, item):
        import time
        time.sleep(0.1)  # Simulate work
        return item * 2

class ThreadController(QObject):
    """Manages worker thread lifecycle."""
    def __init__(self):
        super().__init__()
        self.thread = None
        self.worker = None
    
    def start_work(self, data):
        # Create thread and worker
        self.thread = QThread()
        self.worker = Worker(data)
        
        # Move worker to thread
        self.worker.moveToThread(self.thread)
        
        # Connect signals
        self.worker.finished.connect(self.on_finished)
        self.worker.progress.connect(self.on_progress)
        self.worker.error.connect(self.on_error)
        
        # Thread lifecycle
        self.thread.started.connect(self.worker.process)
        self.thread.finished.connect(self.thread.deleteLater)
        
        # Start thread
        self.thread.start()
    
    def cancel_work(self):
        if self.worker:
            self.worker.cancel()
        if self.thread:
            self.thread.quit()
            self.thread.wait()
    
    @Slot()
    def on_finished(self, result):
        print(f"Work completed: {result}")
        self.cleanup()
    
    @Slot()
    def on_progress(self, percent):
        print(f"Progress: {percent}%")
    
    @Slot()
    def on_error(self, error):
        print(f"Error: {error}")
        self.cleanup()
    
    def cleanup(self):
        self.thread = None
        self.worker = None
```

## QThread Subclass (Simpler Pattern)

For simpler cases, subclass QThread directly:

```python
from PySide6.QtCore import QThread, Signal

class DataProcessor(QThread):
    """Thread that processes data and emits progress."""
    progress = Signal(int)
    result_ready = Signal(list)
    error_occurred = Signal(str)
    finished = Signal()
    
    def __init__(self, input_data, parent=None):
        super().__init__(parent)
        self.input_data = input_data
        self._cancelled = False
    
    def run(self):
        """Thread entry point - called by start()."""
        try:
            results = []
            total = len(self.input_data)
            
            for i, item in enumerate(self.input_data):
                if self._cancelled:
                    self.error_occurred.emit("Cancelled")
                    return
                
                # Process item (heavy work here)
                processed = self.process_item(item)
                results.append(processed)
                
                # Emit progress
                progress_percent = int((i + 1) / total * 100)
                self.progress.emit(progress_percent)
            
            self.result_ready.emit(results)
        except Exception as e:
            self.error_occurred.emit(str(e))
        finally:
            self.finished.emit()
    
    def process_item(self, item):
        import time
        time.sleep(0.05)  # Simulate work
        return str(item).upper()
    
    def cancel(self):
        self._cancelled = True

# Usage
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.processor = None
        
        self.progress = QProgressBar()
        self.start_btn = QPushButton("Start")
        self.cancel_btn = QPushButton("Cancel")
        
        self.start_btn.clicked.connect(self.start_processing)
        self.cancel_btn.clicked.connect(self.cancel_processing)
    
    def start_processing(self):
        data = ["item1", "item2", "item3", "item4", "item5"]
        
        self.processor = DataProcessor(data)
        self.processor.progress.connect(self.progress.setValue)
        self.processor.result_ready.connect(self.on_results)
        self.processor.error_occurred.connect(self.on_error)
        self.processor.finished.connect(self.on_finished)
        
        self.processor.start()
        self.start_btn.setEnabled(False)
    
    def cancel_processing(self):
        if self.processor:
            self.processor.cancel()
    
    def on_results(self, results):
        print(f"Got {len(results)} results")
    
    def on_error(self, error):
        QMessageBox.warning(self, "Error", error)
    
    def on_finished(self):
        self.start_btn.setEnabled(True)
        self.progress.setValue(0)
        self.processor = None
```

## QThreadPool with QRunnable

For parallel execution of independent tasks:

```python
from PySide6.QtCore import QThreadPool, QRunnable, Signal, QObject, QThread
import time

class TaskSignals(QObject):
    """Signals for QRunnable (QRunnable cannot have signals directly)."""
    finished = Signal(object)
    error = Signal(str)
    progress = Signal(int)

class ParallelTask(QRunnable):
    """Runnable task for thread pool."""
    
    def __init__(self, task_id, data):
        super().__init__()
        self.task_id = task_id
        self.data = data
        self.signals = TaskSignals()
        self._cancelled = False
    
    def run(self):
        """Executed by thread pool."""
        try:
            time.sleep(0.5)  # Simulate work
            
            if self._cancelled:
                return
            
            result = {
                "id": self.task_id,
                "processed": str(self.data).upper(),
                "thread": int(QThread.currentThreadId())
            }
            
            self.signals.finished.emit(result)
        except Exception as e:
            self.signals.error.emit(str(e))
    
    def cancel(self):
        self._cancelled = True

class ThreadPoolManager(QObject):
    """Manages parallel task execution."""
    all_finished = Signal(int)
    
    def __init__(self, max_threads=4):
        super().__init__()
        self.pool = QThreadPool()
        self.pool.setMaxThreadCount(max_threads)
        self.active_tasks = {}
        self.completed_count = 0
        self.total_tasks = 0
    
    def run_parallel(self, tasks):
        """Run multiple tasks in parallel."""
        self.completed_count = 0
        self.total_tasks = len(tasks)
        self.active_tasks.clear()
        
        for task_id, data in enumerate(tasks):
            task = ParallelTask(task_id, data)
            task.signals.finished.connect(
                lambda result, tid=task_id: self.on_task_finished(result)
            )
            task.signals.error.connect(self.on_task_error)
            self.active_tasks[task_id] = task
            self.pool.start(task)
    
    def on_task_finished(self, result):
        self.completed_count += 1
        task_id = result["id"]
        del self.active_tasks[task_id]
        
        if self.completed_count >= self.total_tasks:
            self.all_finished.emit(self.completed_count)
    
    def on_task_error(self, error):
        print(f"Task error: {error}")
    
    def cancel_all(self):
        for task in self.active_tasks.values():
            task.cancel()
        self.active_tasks.clear()
```

## QTimer for Periodic Updates

```python
from PySide6.QtCore import QTimer, Slot

class PollingWidget(QWidget):
    def __init__(self):
        super().__init__()
        
        # Create timer
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.on_timeout)
        
        # UI
        self.status_label = QLabel("Last update: Never")
        self.poll_btn = QPushButton("Start Polling")
        self.poll_btn.setCheckable(True)
        
        layout = QVBoxLayout(self)
        layout.addWidget(self.status_label)
        layout.addWidget(self.poll_btn)
        
        self.poll_btn.toggled.connect(self.toggle_polling)
    
    @Slot()
    def toggle_polling(self, checked):
        if checked:
            self.timer.start(1000)  # Poll every second
            self.poll_btn.setText("Stop Polling")
        else:
            self.timer.stop()
            self.poll_btn.setText("Start Polling")
    
    @Slot()
    def on_timeout(self):
        from datetime import datetime
        self.status_label.setText(f"Last update: {datetime.now().strftime('%H:%M:%S')}")
```

## QThreadPool with QRunnable - Fire-and-Forget Pattern

For fire-and-forget tasks where you don't need to wait for results:

```python
from PySide6.QtCore import QThreadPool, QRunnable, Signal, QObject
import time

class BackgroundTask(QRunnable):
    """Runnable for fire-and-forget operations."""
    
    def __init__(self, task_id, data):
        super().__init__()
        self.task_id = task_id
        self.data = data
        self._cancelled = False
    
    def run(self):
        """Executed by thread pool - auto-managed lifecycle."""
        try:
            # Simulate background work
            for i in range(10):
                if self._cancelled:
                    return
                import time
                time.sleep(0.1)
            
            print(f"Task {self.task_id} completed")
            
        except Exception as e:
            # Log error silently for fire-and-forget
            print(f"Task {self.task_id} failed: {e}")

# Usage - fire and forget
task = BackgroundTask(42, "some data")
QThreadPool.globalInstance().start(task)
# Task automatically deleted after run() completes
```

**Key Behaviors:**
- **Auto-delete**: QRunnable is deleted automatically after `run()` completes
- **No explicit lifecycle management needed**: Pool handles creation and destruction
- **Global thread pool**: `QThreadPool.globalInstance()` returns the default singleton
- **Default limit**: Typically 8 threads (can be configured via `setMaxThreadCount()`)
- **Thread recycling**: Completed tasks' threads are reused for new tasks

## moveToThread() Pattern - Worker Object Semantics

### Correct Pattern: Worker + Thread Controller

The **worker object pattern** is the recommended approach for explicit thread control:

```python
from PySide6.QtCore import QThread, Signal, QObject, Slot

class Worker(QObject):
    """Worker owns the work, controller owns the thread."""
    progress = Signal(int)
    finished = Signal(object)
    
    def __init__(self, data):
        super().__init__()
        self.data = data
        self._is_running = False
    
    @Slot()
    def process(self):
        """Main work method - called from thread."""
        self._is_running = True
        try:
            # Heavy computation here
            for i in range(100):
                self.progress.emit(i)
            self.finished.emit(None)
        finally:
            self._is_running = False

class ThreadController(QObject):
    """Controller owns thread and manages worker."""
    def __init__(self):
        super().__init__()
        self.thread = None
        self.worker = None
    
    def start_work(self, data):
        # Create NEW thread and worker
        self.thread = QThread()
        self.worker = Worker(data)
        
        # CRITICAL: Move worker TO thread
        self.worker.moveToThread(self.thread)
        
        # Worker lifetime tied to thread lifetime
        self.thread.started.connect(self.worker.process)
        self.thread.finished.connect(self.thread.quit)
        self.thread.finished.connect(self.thread.deleteLater)
        
        self.thread.start()
```

### Ownership Semantics

| Object | Owner | Lifetime | Deletion |
|--------|-------|----------|----------|
| **Worker** | ThreadController | Until thread.quit() + wait() | worker.deleteLater() |
| **Thread** | ThreadController | Until deleted | thread.deleteLater() |
| **Signals** | Their parent | Until parent deleted | Automatic |

### Common Mistakes to Avoid

```python
# ❌ WRONG: Worker outlives thread
controller = ThreadController()
controller.thread = QThread()
controller.worker = Worker()
controller.thread.moveToThread(controller.worker)  # Wrong direction!
controller.thread.start()
# Problem: Worker destroyed before thread finishes

# ❌ WRONG: Forgetting thread lifecycle
def start_work():
    thread = QThread()
    worker = Worker()
    worker.moveToThread(thread)
    thread.start()  # Never quit() or wait()!
# Problem: Zombie thread keeps running

# ✅ CORRECT: Proper ownership chain
controller = ThreadController()
controller.start_work(data)
# Later when done:
controller.thread.quit()
controller.thread.wait()
# Now delete: controller.worker.deleteLater()
```

## Thread Lifecycle Management

### Thread Signals and State

```python
from PySide6.QtCore import QThread, Signal, QObject

class MyThread(QThread):
    started = Signal()  # Emitted when thread() is called
    finished = Signal()  # Emitted when finished() is called
    isRunningChanged = Signal(bool)  # Emitted when running state changes
    
    def __init__(self):
        super().__init__()
        self._running = False
    
    def run(self):
        self._running = True
        self.isRunningChanged.emit(True)
        self.started.emit()
        try:
            # Work here
            pass
        finally:
            self.finished.emit()
```

### Proper Cleanup Pattern

```python
class ThreadManager(QObject):
    def __init__(self):
        super().__init__()
        self.threads = {}
    
    def create_thread(self, name, worker):
        thread = QThread()
        thread.setObjectName(name)
        
        worker.moveToThread(thread)
        thread.started.connect(worker.start_work)
        
        # Cleanup when thread finishes
        thread.finished.connect(self._on_thread_finished, Qt.QueuedConnection)
        
        thread.start()
        self.threads[name] = thread
        
        return thread
    
    def _on_thread_finished(self, thread, name):
        """Clean up resources when thread exits."""
        # Signal for parent to handle cleanup
        self.on_thread_cleanup.emit(thread, name)
        
        # Auto-delete worker
        if name in self.thread_workers:
            worker = self.thread_workers.pop(name)
            worker.deleteLater()
        
        # Thread will be deleted by connect above
        print(f"Thread {name} cleaned up")
    
    def on_thread_cleanup(self, thread, name):
        """Override to handle custom cleanup."""
        del self.threads[name]

# Usage
manager = ThreadManager()
manager.thread_workers = {"worker1": worker}
thread = manager.create_thread("WorkerThread", worker)
# When thread finishes, worker is auto-deleted
```

### Graceful Shutdown Patterns

```python
class GracefulWorker(QObject):
    finished = Signal()
    
    def __init__(self):
        super().__init__()
        self._shutdown_requested = False
        self._current_task = None
    
    def shutdown(self):
        """Request graceful shutdown."""
        self._shutdown_requested = True
        if self._current_task:
            self._current_task.cancel()
    
    def run(self):
        while not self._shutdown_requested:
            # Check shutdown before starting new task
            if self._check_ready_for_work():
                self._do_work()
            else:
                import time
                time.sleep(0.01)  # Small delay to avoid busy-wait
        
        self.finished.emit()

# Shutdown sequence
def shutdown_worker(worker, thread):
    """Clean shutdown of worker and thread."""
    worker.shutdown()
    
    # Wait for current work to complete
    for _ in range(100):
        if worker.isFinished():  # Qt isSignal (weak reference)
            break
        import time
        time.sleep(0.1)
    
    # Quit thread
    thread.quit()
    thread.wait()
    
    # Final cleanup
    worker.deleteLater()
    thread.deleteLater()
```

## Thread Safety - Advanced Patterns

### Thread-Safe State Management

```python
from PySide6.QtCore import QObject, QObject, QMutex, QMutexLocker, QAtomicPointer
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

### Avoiding UI State Races

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

### Resource Exhaustion Prevention

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

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| UI freezes | Blocking operation in main thread | Move to worker thread |
| Crashes on widget access | Accessing UI from worker thread | Use signals instead |
| Memory leaks | Thread not cleaned up | Use deleteLater() and proper lifecycle |
| Deadlocks | Multiple mutexes acquired in different order | Always acquire in same order, use timeout |
| Race conditions | Shared data without locks | Use QMutex or atomic operations |

## Best Practices

1. **Always use signals for cross-thread communication** - Direct widget access from threads causes crashes
2. **Keep worker objects thread-affinity aware** - Never assume QObject is in main thread
3. **Clean up threads properly** - Use deleteLater() and quit() + wait()
4. **Handle cancellation** - Check flags periodically in long operations
5. **Use QThreadPool for parallel independent tasks** - Default pool manages resource limits
6. **Use moveToThread() for explicit thread control** - Worker object pattern is recommended
7. **Never use time.sleep() in main thread** - Use QTimer or workers instead
8. **Keep locks short-lived** - Only hold mutexes for critical section duration
9. **Use QReadWriteLock for read-heavy data** - Multiple readers possible, single writer
10. **Monitor thread pool limits** - Set maxThreadCount to prevent resource exhaustion

## Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| UI crashes on widget access | Widget accessed from worker thread | Always use signals to update UI from main thread |
| Deadlock | Multiple mutexes acquired in different order | Always acquire in consistent order, use timeouts |
| Race conditions | Shared data without locks | Use QMutex, QAtomicPointer, or atomic operations |
| Memory leaks | Threads not cleaned up | Use deleteLater() on threads and workers |
| Thread not stopping | No quit() + wait() sequence | Always call thread.quit() then thread.wait() |
| Signals firing from wrong thread | AutoConnection uses queued delivery | AutoConnection is correct - don't change |
| Re-entrancy issues | Signal handler calls slot recursively | Use flags to track state changes |
| Resource exhaustion | Unlimited thread pool threads | Set maxThreadCount on QThreadPool |
| Busy-wait loops | Thread polling without sleep | Use QTimer instead of polling |
| Lock not released | Exception before unlock | Use QMutexLocker for RAII-style cleanup |

### Top 5 Mistakes to Avoid

1. **Never access UI from worker threads** - The most common crash cause
   ```python
   # ❌ CRASH: Direct UI access
   def run(self):
       self.label.setText("Done")  # Crashes!
   
   # ✅ SAFE: Use signals
   def run(self):
       self.finished.emit("Done")  # UI updated in main thread
   ```

2. **Forgetting thread lifecycle management** - Threads become zombies
   ```python
   # ❌ BAD: No cleanup
   thread = QThread()
   thread.start()  # Never quit() or wait()
   
   # ✅ GOOD: Proper lifecycle
   thread.start()
   thread.quit()
   thread.wait()  # Wait for thread to finish
   ```

3. **Acquiring locks in wrong order** - Deadlock
   ```python
   # ❌ DEADLOCK
   def do_work(self):
       with lock_a:
           with lock_b:
               pass
   
   def do_other_work(self):
       with lock_b:  # Different order!
           with lock_a:
               pass
   
   # ✅ SAFE: Consistent ordering
   # Always acquire locks in same order (e.g., by ID)
   ```

4. **Using locks too long** - Performance issues
   ```python
   # ❌ BAD: Lock held for long operation
   with lock:
       result = heavy_computation()
   
   # ✅ GOOD: Hold lock only for data access
   with lock:
       data = self.shared_data
   result = heavy_computation(data)  # Outside lock
   ```

5. **Forgetting to check cancellation** - Threads don't stop
   ```python
   # ❌ BAD: Infinite loop
   def run(self):
       while True:
           do_work()
   
   # ✅ GOOD: Check cancellation flag
   def run(self):
       while not self._cancelled:
           if self._work_done():
               break
           do_work()
   ```

## References

### Official Documentation
- **Qt Threads and Objects**: https://doc.qt.io/qt-6/threads-and-qobjects.html
- **QThread**: https://doc.qt.io/qt-6/qthread.html
- **QThreadPool**: https://doc.qt.io/qt-6/qpthreadpool.html
- **QMutex**: https://doc.qt.io/qt-6/qmutex.html
- **QMutexLocker**: https://doc.qt.io/qt-6/qmutexlocker.html
- **QReadWriteLock**: https://doc.qt.io/qt-6/qreadwritelock.html
- **QAtomicPointer**: https://doc.qt.io/qt-6/qatomicpointer.html
- **Signal/Slot**: https://doc.qt.io/qt-6/signalsandslots.html

### Qt for Python (PySide6/PyQt6)
- **PySide6 QThread**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QThread.html
- **PySide6 QThreadPool**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QThreadPool.html
- **PyQt6 QThread**: https://www.riverbankcomputing.com/static/Docs/PyQt6/qthread.html

### Community Resources
- **Threading Best Practices**: https://realpython.com/python-threading/ (adapted for Qt)
- **Qt Multithreading Guide**: https://www.qt.io/blog/solving-multithreading-problems-in-qt-6
- **PySide6 Examples**: https://github.com/pyside/pyside-examples
- **PyQt6 Threading**: https://www.riverbankcomputing.com/static/Docs/PyQt6/qthread.html#queuing-mechanism

### Advanced Topics
- **Atomic Operations**: https://doc.qt.io/qt-6/qatomicint.html (atomic types)
- **Inter-Thread Communication**: https://doc.qt.io/qt-6/inter-thread-communication.html
- **Thread Safety Analysis**: https://doc.qt.io/qt-6/thread-safety-analysis.html

### Testing
- **pytest-qt for Threading Tests**: https://pytest-qt.readthedocs.io/
- **Async Testing Patterns**: https://doc.qt.io/qt-6/async-testing.html
