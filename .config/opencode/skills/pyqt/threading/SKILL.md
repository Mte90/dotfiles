---
name: pyqt-threading
description: Use when handling PyQt/PySide6 threading - QThread patterns, QThreadPool/QRunnable, thread safety rules, moveToThread, Qt Concurrent, QTimer, testing threaded code, lifecycle management
metadata:
  author: mte90
  version: 3.0.0
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

# PyQt Threading - Core Patterns

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

## Deep Dives

For detailed coverage of advanced patterns, load these reference files:

- **Pool Patterns** (`references/pool-patterns.md`) - QThread Subclass, QThreadPool/QRunnable, QTimer, Fire-and-Forget
- **Qt Concurrent** (`references/qt-concurrent.md`) - Map/filter/reduce operations, progress tracking, simple background tasks
- **Lifecycle & Cleanup** (`references/lifecycle-cleanup.md`) - Thread signals, proper cleanup, graceful shutdown
- **Advanced Safety** (`references/advanced-safety.md`) - Thread-safe state, UI state races, resource exhaustion
- **Testing** (`references/testing.md`) - pytest-qt patterns, signal testing, thread lifecycle testing, race condition tests

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