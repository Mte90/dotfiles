# Lifecycle & Cleanup - Deep Dive

> This reference file is loaded on demand from ../SKILL.md.

## Thread Signals and State

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

## Proper Cleanup Pattern

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

## Graceful Shutdown Patterns

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