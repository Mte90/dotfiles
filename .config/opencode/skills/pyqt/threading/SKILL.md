---
name: pyqt-threading
description: "PyQt/PySide6 threading and concurrency - QThread, QThreadPool, QTimer, thread safety, concurrent patterns"
metadata:
  author: OSS AI Skills
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

## Thread-Safe Data Sharing

```python
from PySide6.QtCore import QMutex, QMutexLocker, QReadWriteLock

class SharedData:
    """Thread-safe data container."""
    
    def __init__(self):
        self._data = {}
        self._mutex = QMutex()
    
    def set_value(self, key, value):
        """Thread-safe write."""
        locker = QMutexLocker(self._mutex)
        self._data[key] = value
    
    def get_value(self, key, default=None):
        """Thread-safe read."""
        locker = QMutexLocker(self._mutex)
        return self._data.get(key, default)
    
    def get_all(self):
        """Thread-safe copy of all data."""
        locker = QMutexLocker(self._mutex)
        return dict(self._data)

class ReadWriteData:
    """Read-write lock for read-heavy workloads."""
    
    def __init__(self):
        self._data = {}
        self._lock = QReadWriteLock()
    
    def read_value(self, key):
        """Multiple readers can hold the lock."""
        self._lock.lockForRead()
        try:
            return self._data.get(key)
        finally:
            self._lock.unlock()
    
    def write_value(self, key, value):
        """Only one writer at a time."""
        self._lock.lockForWrite()
        try:
            self._data[key] = value
        finally:
            self._lock.unlock()
```

## Best Practices

1. **Always use signals for cross-thread communication**
2. **Keep worker objects thread-affinity aware** - Don't assume they're in main thread
3. **Clean up threads properly** - Use deleteLater() and quit() + wait()
4. **Handle cancellation** - Check flags periodically in long operations
5. **Use QThreadPool for parallel independent tasks**
6. **Use QThread.moveToThread() for single long operations**
7. **Never use time.sleep() in main thread** - Use timers or workers instead

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| UI freezes | Blocking operation in main thread | Move to worker thread |
| Crashes on widget access | Accessing UI from worker thread | Use signals instead |
| Memory leaks | Thread not cleaned up | Use deleteLater() and proper lifecycle |
| Deadlocks | Multiple mutexes acquired in different order | Always acquire in same order, use timeout |
| Race conditions | Shared data without locks | Use QMutex or atomic operations |

## References

- **Qt Threads**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QThread.html
- **Thread Basics**: https://doc.qt.io/qtforpython-6/threads_and_qobjects.html
- **QThreadPool**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QThreadPool.html
- **QTimer**: https://doc.qt.io/qtforpython-6/PySide6/QtCore/QTimer.html
