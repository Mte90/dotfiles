# Pool Patterns - Deep Dive

> This reference file is loaded on demand from ../SKILL.md.

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