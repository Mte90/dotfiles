# Testing Threaded Code - Deep Dive

> This reference file is loaded on demand from ../SKILL.md.

## Testing Worker Threads with pytest-qt

```python
# test_threading.py
import pytest
from PySide6.QtCore import QThread, Signal, QObject
from unittest.mock import Mock

def test_worker_thread_emits_progress(qtbot):
    """Test that worker thread emits progress signals."""
    
    class TestWorker(QThread):
        progress = Signal(int)
        
        def run(self):
            for i in range(5):
                self.progress.emit(i * 20)
    
    worker = TestWorker()
    
    # Wait for signal with timeout
    with qtbot.waitSignal(worker.progress, timeout=1000):
        worker.start()
    
    # Collect all signals
    signals = []
    worker.progress.connect(signals.append)
    
    worker.start()
    worker.wait()
    
    assert len(signals) == 5
    assert signals == [0, 20, 40, 60, 80]

def test_thread_cancellation(qtbot):
    """Test thread can be cancelled."""
    
    class CancellableWorker(QThread):
        finished = Signal()
        
        def __init__(self):
            super().__init__()
            self._cancelled = False
        
        def run(self):
            for i in range(100):
                if self._cancelled:
                    return
                import time
                time.sleep(0.01)
            self.finished.emit()
        
        def cancel(self):
            self._cancelled = True
    
    worker = CancellableWorker()
    worker.start()
    worker.cancel()
    worker.wait(100)  # Wait with timeout
    
    # Should complete without emitting finished
    assert not worker.isFinished() or worker._cancelled
```

## Testing QThreadPool Tasks

```python
def test_thread_pool_parallel_execution(qtbot):
    """Test that tasks run in parallel."""
    from PySide6.QtCore import QThreadPool, QRunnable, QObject, Signal
    import time
    
    class TestTask(QRunnable):
        task_started = Signal(int)
        task_finished = Signal(int)
        
        def __init__(self, task_id):
            super().__init__()
            self.task_id = task_id
        
        def run(self):
            self.task_started.emit(self.task_id)
            time.sleep(0.1)
            self.task_finished.emit(self.task_id)
    
    pool = QThreadPool()
    started_tasks = []
    finished_tasks = []
    
    for i in range(4):
        task = TestTask(i)
        task.task_started.connect(started_tasks.append)
        task.task_finished.connect(finished_tasks.append)
        pool.start(task)
    
    # Wait for all tasks
    with qtbot.waitSignal(pool.finished, timeout=5000):
        pass
    
    # All tasks should have completed
    assert len(finished_tasks) == 4
    assert set(finished_tasks) == {0, 1, 2, 3}

def test_thread_pool_max_threads(qtbot):
    """Test thread pool respects max thread count."""
    from PySide6.QtCore import QThreadPool, QRunnable
    import time
    
    active_count = 0
    max_active = 0
    
    class CountingTask(QRunnable):
        def run(self):
            nonlocal active_count, max_active
            active_count += 1
            max_active = max(max_active, active_count)
            time.sleep(0.2)
            active_count -= 1
    
    pool = QThreadPool()
    pool.setMaxThreadCount(2)
    
    for _ in range(6):
        pool.start(CountingTask())
    
    with qtbot.waitSignal(pool.finished, timeout=10000):
        pass
    
    # Max concurrent should not exceed 2
    assert max_active <= 2
```

## Testing Thread-Safe Data Structures

```python
def test_mutex_protected_data(qtbot):
    """Test thread-safe data access."""
    from PySide6.QtCore import QMutex, QMutexLocker, QThread, Signal
    
    class SharedData:
        def __init__(self):
            self._value = 0
            self._mutex = QMutex()
        
        def increment(self):
            locker = QMutexLocker(self._mutex)
            self._value += 1
        
        def get(self):
            locker = QMutexLocker(self._mutex)
            return self._value
    
    shared = SharedData()
    
    class Incrementer(QThread):
        def run(self):
            for _ in range(100):
                shared.increment()
    
    threads = [Incrementer() for _ in range(10)]
    
    for t in threads:
        t.start()
    
    for t in threads:
        t.wait()
    
    # Should be exactly 1000 after 10 threads x 100 increments
    assert shared.get() == 1000

def test_race_condition_prevention(qtbot):
    """Test that race conditions are prevented."""
    from PySide6.QtCore import QReadWriteLock, QThread
    
    class ReadWriteData:
        def __init__(self):
            self._data = 0
            self._lock = QReadWriteLock()
        
        def read(self):
            self._lock.lockForRead()
            try:
                return self._data
            finally:
                self._lock.unlock()
        
        def write(self, value):
            self._lock.lockForWrite()
            try:
                self._data = value
            finally:
                self._lock.unlock()
    
    data = ReadWriteData()
    errors = []
    
    def reader():
        for _ in range(100):
            try:
                _ = data.read()
            except Exception as e:
                errors.append(e)
    
    def writer():
        for i in range(100):
            try:
                data.write(i)
            except Exception as e:
                errors.append(e)
    
    threads = [QThread(run=r) for r in [reader, writer, reader, writer]]
    for t in threads:
        t.start()
    for t in threads:
        t.wait()
    
    assert len(errors) == 0
```

## Testing Signal/Slot Cross-Thread Communication

```python
def test_cross_thread_signal_delivery(qtbot):
    """Test signals work correctly across threads."""
    from PySide6.QtCore import QThread, Signal, QObject, Qt
    
    class Worker(QObject):
        result = Signal(object)
        
        def __init__(self, data):
            super().__init__()
            self.data = data
        
        def process(self):
            # Simulate work
            import time
            time.sleep(0.1)
            self.result.emit({"processed": self.data})
    
    class TestController(QObject):
        def __init__(self):
            super().__init__()
            self.received = None
        
        def handle_result(self, result):
            self.received = result
    
    controller = TestController()
    thread = QThread()
    worker = Worker("test_data")
    
    worker.moveToThread(thread)
    worker.result.connect(controller.handle_result, Qt.QueuedConnection)
    thread.started.connect(worker.process)
    
    with qtbot.waitSignal(thread.finished, timeout=2000):
        thread.start()
    
    assert controller.received == {"processed": "test_data"}
    
    thread.quit()
    thread.wait()
```

## Mocking Thread Dependencies

```python
def test_worker_with_mocked_dependencies():
    """Test worker with mocked external dependencies."""
    from unittest.mock import Mock, patch
    
    class ExternalService:
        def fetch_data(self):
            return {"real": "data"}
    
    class WorkerWithDependency(QThread):
        result = Signal(object)
        
        def __init__(self, service):
            super().__init__()
            self.service = service
        
        def run(self):
            data = self.service.fetch_data()
            self.result.emit(data)
    
    mock_service = Mock()
    mock_service.fetch_data.return_value = {"mocked": "data"}
    
    worker = WorkerWithDependency(mock_service)
    results = []
    worker.result.connect(results.append)
    
    worker.start()
    worker.wait()
    
    assert results[0] == {"mocked": "data"}
    mock_service.fetch_data.assert_called_once()
```

## Testing Thread Lifecycle

```python
def test_thread_proper_cleanup(qtbot):
    """Test that threads are properly cleaned up."""
    from PySide6.QtCore import QThread, Signal
    
    cleanup_called = False
    
    class TestThread(QThread):
        finished = Signal()
        
        def __init__(self):
            super().__init__()
            self._deleted = False
        
        def run(self):
            import time
            time.sleep(0.1)
            self.finished.emit()
        
        def __del__(self):
            nonlocal cleanup_called
            cleanup_called = True
    
    thread = TestThread()
    thread.start()
    
    with qtbot.waitSignal(thread.finished, timeout=2000):
        thread.wait()
        thread.deleteLater()
    
    # Process events to trigger deletion
    qtbot.wait(100)
    
    assert cleanup_called
```