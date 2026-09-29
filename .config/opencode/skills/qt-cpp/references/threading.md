This reference file is loaded on demand from ../SKILL.md.

# Threading

## QThread

```cpp
class WorkerThread : public QThread {
    Q_OBJECT
public:
    explicit WorkerThread(QObject *parent = nullptr) : QThread(parent) {}

protected:
    void run() override {
        // Long-running operation
        for (int i = 0; i < 100; ++i) {
            QThread::msleep(100);
            emit progress(i);
        }
    }

signals:
    void progress(int value);
};

// Usage
class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QMainWindow(parent) {
        QPushButton *startButton = new QPushButton("Start", this);
        QProgressBar *progressBar = new QProgressBar(this);

        m_worker = new WorkerThread(this);

        connect(startButton, &QPushButton::clicked, this, [this]() {
            m_worker->start();
        });

        connect(m_worker, &WorkerThread::progress, progressBar,
                &QProgressBar::setValue);

        connect(m_worker, &WorkerThread::finished, this, []() {
            qDebug() << "Worker finished";
        });
    }

private:
    WorkerThread *m_worker;
};
```

## QThreadPool and QRunnable

```cpp
class MyTask : public QRunnable {
public:
    explicit MyTask(int id) : m_id(id) {}

    void run() override {
        // Background task
        qDebug() << "Task" << m_id << "running in thread:"
                 << QThread::currentThread();
        QThread::sleep(2);
    }

private:
    int m_id;
};

// Usage
QThreadPool pool;
pool.setMaxThreadCount(4);

for (int i = 0; i < 10; ++i) {
    pool.start(new MyTask(i));
}

// Wait for all tasks
pool.waitForDone();
```

## QtConcurrent

```cpp
#include <QtConcurrent>
#include <QFuture>
#include <QFutureWatcher>

// Run function in background
int heavyCalculation(int n) {
    QThread::sleep(2);
    return n * n;
}

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);

    // Run in separate thread
    QFuture<int> future = QtConcurrent::run(heavyCalculation, 42);

    // Watch for completion
    QFutureWatcher<int> watcher;
    connect(&watcher, &QFutureWatcher<int>::finished, &app, [&future]() {
        qDebug() << "Result:" << future.result();
        app.quit();
    });

    watcher.setFuture(future);

    return app.exec();
}

// Map-Reduce pattern
QVector<int> data = {1, 2, 3, 4, 5};

// Map: apply function to all elements
QFuture<QVector<int>> mapped = QtConcurrent::mapped(data, [](int n) {
    return n * n;
});

// Filter: keep elements that match
QFuture<QVector<int>> filtered = QtConcurrent::filtered(data, [](int n) {
    return n > 2;
});
```

## moveToThread

```cpp
class Worker : public QObject {
    Q_OBJECT
public:
    explicit Worker(QObject *parent = nullptr) : QObject(parent) {}

public slots:
    void doWork() {
        qDebug() << "Worker running in thread:"
                 << QThread::currentThread();
        QThread::sleep(2);
        emit workFinished("Done");
    }

signals:
    void workFinished(const QString &result);
};

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QMainWindow(parent) {
        QThread *thread = new QThread(this);
        m_worker = new Worker();

        // Move worker to thread
        m_worker->moveToThread(thread);

        // Start thread
        connect(thread, &QThread::started, m_worker, &Worker::doWork);
        connect(m_worker, &Worker::workFinished, this,
                [](const QString &result) {
            qDebug() << "Result:" << result;
        });
        connect(m_worker, &Worker::workFinished, thread, &QThread::quit);
        connect(thread, &QThread::finished, thread, &QThread::deleteLater);
        connect(thread, &QThread::finished, m_worker, &Worker::deleteLater);

        thread->start();
    }

private:
    Worker *m_worker;
};
```