---
name: kate-plugin
description: "Develop C++ plugins for Kate text editor using KTextEditor Framework, CMake with ECM, Qt threading, and KDE plugin architecture"
metadata:
  author: mte90
  version: "2.0.0"
  tags:
    - kate
    - kde
    - text-editor
    - plugin
    - c++
    - qt
    - kde-frameworks
---

# Kate Plugin Development

C++ plugins for Kate using KTextEditor Framework, KDE Frameworks, and Qt.

## Overview

Kate plugins extend functionality through C++ using KTextEditor framework.

```
/usr/share/kate/plugins/    # System
~/.local/share/kate/plugins/ # User
```

## Plugin Architecture

```cpp
#include <KPluginFactory>
#include <KTextEditor/Plugin>

class MyPlugin : public KTextEditor::Plugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.KTextEditor.Plugin" FILE "metadata.json")
public:
    explicit MyPlugin(QObject *parent, const QVariantList &)
        : KTextEditor::Plugin(parent) {}
    ~MyPlugin() override = default;

    QWidget *createConfigWidget(QWidget *p) override { return new ConfigWidget(p); }
    void readConfig(KConfigGroup &g) override { m_enabled = g.readEntry("Enabled", true); }
    void writeConfig(KConfigGroup &g) override { g.writeEntry("Enabled", m_enabled); }
    void init() override {}
    void addView(KTextEditor::MainWindow *mw) override {
        auto *v = mw->activeView();
        if (v) connect(v->document(), &KTextEditor::Document::textChanged, this, &MyPlugin::onTextChanged);
    }
    void removeView(KTextEditor::MainWindow *) override {}
private slots:
    void onTextChanged(KTextEditor::Document *doc) { qDebug() << doc->url(); }
private:
    bool m_enabled = true;
};

K_PLUGIN_FACTORY_WITH_JSON(MyPluginFactory, "metadata.json", registerPlugin<MyPlugin>();)
```

```json
{
    "KPlugin": {
        "Name": "My Plugin",
        "Description": "A C++ plugin for Kate",
        "Icon": "kate",
        "Authors": [{"Name": "Dev", "Email": "dev@example.com"}],
        "Version": "1.0.0",
        "License": "GPL-2.0-or-later",
        "ServiceTypes": ["KTextEditor/Plugin"],
        "Category": "Language"
    },
    "X-KTextEditor": {"APIVersion": "5"}
}
```

```cmake
cmake_minimum_required(VERSION 3.16)
project(myplugin VERSION 1.0.0)
set(CMAKE_CXX_STANDARD 17)
find_package(ECM 5.90 REQUIRED NO_MODULE)
find_package(KF5 REQUIRED COMPONENTS CoreAddons Config KTextEditor WidgetsAddons)
include(KDEInstallDirs)
include(KDECMakeSettings)

kcoreaddons_add_plugin(myplugin INSTALL_NAMESPACE "kate"
    SOURCES myplugin.cpp configwidget.cpp
    LIBRARIES KF5::CoreAddons KF5::ConfigGui KF5::KTextEditor)
install(FILES metadata.json DESTINATION ${KDE_INSTALL_KTPLUGINDIR}/myplugin)
```

## KTextEditor API

```cpp
#include <KTextEditor/Document>
#include <KTextEditor/View>
#include <KTextEditor/Range>
#include <KTextEditor/Cursor>

class DocumentHandler {
public:
    explicit DocumentHandler(KTextEditor::Document *doc) : m_doc(doc) {}
    void insertText(const KTextEditor::Cursor &cur, const QString &text) { m_doc->insertText(cur, text); }
    void replaceText(const KTextEditor::Range &range, const QString &text) { m_doc->replaceText(range, text); }
    QString getText() const { return m_doc->text(); }
    QString getLine(int n) const { return m_doc->line(n); }
    int lineCount() const { return m_doc->lines(); }
    KTextEditor::Range search(const QString &pat, const KTextEditor::Cursor &start) { return m_doc->searchText(pat, start); }
private:
    KTextEditor::Document *m_doc;
};

class ViewHandler {
public:
    explicit ViewHandler(KTextEditor::View *view) : m_view(view) {}
    KTextEditor::Cursor getCursorPosition() const { return m_view->cursorPosition(); }
    void setCursorPosition(int line, int col) { m_view->setCursorPosition(line, col); }
    QString getSelection() const { return m_view->selectionText(); }
    void setSelection(const KTextEditor::Range &range) { m_view->setSelection(range); }
    void clearSelection() { m_view->clearSelection(); }
    void toggleFolding(const KTextEditor::Range &range) { m_view->toggleFolding(range); }
private:
    KTextEditor::View *m_view;
};

void positions(KTextEditor::Document *doc) {
    KTextEditor::Cursor cursor(10, 5);
    KTextEditor::Range range(10, 0, 10, 20);
    if (range.isValid()) { QString text = range.text(doc); bool contains = range.contains(cursor); }
}
```

## CMake Build System

```cmake
cmake_minimum_required(VERSION 3.16)
project(myplugin VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(ECM 5.90 REQUIRED NO_MODULE)
find_package(KF5 REQUIRED COMPONENTS CoreAddons Config KTextEditor WidgetsAddons)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)

kcoreaddons_add_plugin(myplugin INSTALL_NAMESPACE "kate"
    SOURCES main.cpp myplugin.cpp configwidget.cpp
    LIBRARIES KF5::CoreAddons KF5::ConfigGui KF5::KTextEditor)

enable_testing()
find_package(Qt5 REQUIRED COMPONENTS Test)
qt5_add_tests(test_myplugin SOURCES test_myplugin.cpp LIBRARIES Qt5::Test KF5::KTextEditor)

install(TARGETS myplugin LIBRARY DESTINATION ${KDE_INSTALL_KTPLUGINDIR}/myplugin)
install(FILES metadata.json DESTINATION ${KDE_INSTALL_KTPLUGINDIR}/myplugin)
```

```cpp
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>

QJsonObject loadConfig(const QString &path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return {};
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    return doc.object();
}

void saveConfig(const QString &path, const QJsonObject &config) {
    QFile file(path);
    if (file.open(QIODevice::WriteOnly)) file.write(QJsonDocument(config).toJson(QJsonDocument::Indented));
}
```

## Threaded Agent Architecture

```cpp
#include <QThread>
#include <QQueue>
#include <QMutex>
#include <QWaitCondition>

class AgentThread : public QThread {
    Q_OBJECT
public:
    explicit AgentThread(QObject *parent = nullptr) : QThread(parent), m_running(true) {}
    ~AgentThread() override { m_running = false; m_condition.wakeOne(); wait(); }
    void enqueueTask(const QString &task) { QMutexLocker locker(&m_mutex); m_tasks.enqueue(task); m_condition.wakeOne(); }
protected:
    void run() override {
        while (m_running) {
            QMutexLocker locker(&m_mutex);
            while (m_tasks.isEmpty() && m_running) m_condition.wait(&m_mutex);
            if (!m_running) break;
            QString task = m_tasks.dequeue();
            locker.unlock();
            processTask(task);
        }
    }
private:
    void processTask(const QString &task) { emit taskCompleted(task, "Result: " + task); }
signals:
    void taskCompleted(const QString &task, const QString &result);
private:
    QQueue<QString> m_tasks; QMutex m_mutex; QWaitCondition m_condition; bool m_running;
};

class AgentManager : public QObject {
    Q_OBJECT
public:
    explicit AgentManager(QObject *parent = nullptr) : QObject(parent), m_agentThread(new AgentThread(this)) {
        connect(m_agentThread.data(), &AgentThread::taskCompleted, this, &AgentManager::onTaskCompleted, Qt::QueuedConnection);
        m_agentThread->start();
    }
    void enqueueAgentTask(const QString &task) { m_agentThread->enqueueTask(task); }
private slots:
    void onTaskCompleted(const QString &task, const QString &result) { qDebug() << "Task:" << task; emit resultReady(task, result); }
signals:
    void resultReady(const QString &task, const QString &result);
private:
    QScopedPointer<AgentThread> m_agentThread;
};

struct AgentTask { QString id; QString data; };
struct AgentResult { QString id; QString output; };

class AgentLoop : public QObject {
    Q_OBJECT
public:
    explicit AgentLoop(QObject *parent = nullptr) : QObject(parent), m_thread(new QThread(this)) {
        m_processor = new AgentProcessor();
        m_processor->moveToThread(m_thread);
        connect(this, &AgentLoop::taskEnqueued, m_processor, &AgentProcessor::processTask, Qt::QueuedConnection);
        connect(m_processor, &AgentProcessor::taskFinished, this, &AgentLoop::onTaskFinished, Qt::QueuedConnection);
        m_thread->start();
    }
    ~AgentLoop() override { m_thread->quit(); m_thread->wait(); }
    void enqueue(const AgentTask &task) { QMutexLocker locker(&m_mutex); m_queue.enqueue(task); emit taskEnqueued(task); }
private slots:
    void onTaskFinished(const AgentResult &result) {
        emit taskCompleted(result);
        QMutexLocker locker(&m_mutex);
        if (!m_queue.isEmpty()) emit taskEnqueued(m_queue.dequeue());
    }
signals:
    void taskEnqueued(const AgentTask &task);
    void taskCompleted(const AgentResult &result);
private:
    QThread *m_thread; AgentProcessor *m_processor; QQueue<AgentTask> m_queue; QMutex m_mutex;
};
```

## Interface-Based Design

```cpp
#include <memory>
#include <QString>
#include <QVariant>

class IThreadStorage {
public:
    virtual ~IThreadStorage() = default;
    virtual void store(const QString &key, const QVariant &value) = 0;
    virtual QVariant retrieve(const QString &key) = 0;
    virtual bool has(const QString &key) = 0;
    virtual void remove(const QString &key) = 0;
    virtual void clear() = 0;
};

class JsonThreadStorage : public IThreadStorage {
public:
    explicit JsonThreadStorage(const QString &filePath) : m_filePath(filePath) { load(); }
    void store(const QString &key, const QVariant &value) override { m_data[key] = QJsonValue::fromVariant(value); save(); }
    QVariant retrieve(const QString &key) override { return m_data.contains(key) ? m_data[key].toVariant() : QVariant(); }
    bool has(const QString &key) override { return m_data.contains(key); }
    void remove(const QString &key) override { m_data.remove(key); save(); }
    void clear() override { m_data = QJsonObject(); save(); }
private:
    void load() { QFile f(m_filePath); if (f.open(QIODevice::ReadOnly)) m_data = QJsonDocument::fromJson(f.readAll()).object(); }
    void save() { QFile f(m_filePath); if (f.open(QIODevice::WriteOnly)) f.write(QJsonDocument(m_data).toJson()); }
    QString m_filePath; QJsonObject m_data;
};

class MemoryThreadStorage : public IThreadStorage {
public:
    void store(const QString &key, const QVariant &value) override { m_data[key] = value; }
    QVariant retrieve(const QString &key) override { return m_data.value(key); }
    bool has(const QString &key) override { return m_data.contains(key); }
    void remove(const QString &key) override { m_data.remove(key); }
    void clear() override { m_data.clear(); }
private:
    QMap<QString, QVariant> m_data;
};

class AgentService {
public:
    explicit AgentService(std::unique_ptr<IThreadStorage> storage) : m_storage(std::move(storage)) {}
    void runAgent(const QString &taskId) { m_storage->store("lastTask", taskId); m_storage->store("lastResult", processTask(taskId)); }
private:
    QString processTask(const QString &id) { return "Processed: " + id; }
    std::unique_ptr<IThreadStorage> m_storage;
};
```

## Configuration with KConfig/QSettings

```cpp
#include <KSharedConfig>
#include <KConfigGroup>

class PluginConfig {
public:
    explicit PluginConfig() : m_config(KSharedConfig::openConfig()), m_group(m_config->group("Plugin")) {}
    void load() { m_enabled = m_group.readEntry("Enabled", true); m_maxThreads = m_group.readEntry("MaxThreads", 4); }
    void save() { m_group.writeEntry("Enabled", m_enabled); m_group.writeEntry("MaxThreads", m_maxThreads); m_config->sync(); }
    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool v) { m_enabled = v; }
private:
    KSharedConfigPtr m_config; KConfigGroup m_group;
    bool m_enabled = true; int m_maxThreads = 4;
};

class StructuredConfig {
public:
    QJsonObject toJsonObject() const { QJsonObject obj; obj["enabled"] = m_enabled; QJsonObject t; t["max"] = m_maxThreads; obj["threads"] = t; return obj; }
    void fromJsonObject(const QJsonObject &obj) { m_enabled = obj["enabled"].toBool(true); if (obj.contains("threads")) m_maxThreads = obj["threads"].toObject()["max"].toInt(4); }
private:
    bool m_enabled = true; int m_maxThreads = 4;
};

class ConfigMigrator {
public:
    static void migrate(KConfigGroup &group) {
        int version = group.readEntry("ConfigVersion", 0);
        if (version < 2) { group.writeEntry("Plugin.Enabled", group.readEntry("Enabled", true)); group.writeEntry("ConfigVersion", 2); }
    }
};
```

## Permission System

```cpp
#include <QSet>

enum class Permission { ReadDocument, WriteDocument, AccessNetwork };

class PermissionManager {
public:
    enum class Decision { Granted, Denied, Pending };
    Decision requestPermission(Permission perm, const QString &reason) {
        if (m_granted.contains(perm)) return Decision::Granted;
        emit permissionRequested(perm, reason);
        return Decision::Pending;
    }
    void grantPermission(Permission perm) { m_granted.insert(perm); emit permissionGranted(perm); }
    void denyPermission(Permission perm) { m_denied.insert(perm); emit permissionDenied(perm); }
    bool hasPermission(Permission perm) const { return m_granted.contains(perm); }
signals:
    void permissionRequested(Permission perm, const QString &reason);
    void permissionGranted(Permission perm);
    void permissionDenied(Permission perm);
private:
    QSet<Permission> m_granted, m_denied;
};

class DocumentAccessController {
public:
    explicit DocumentAccessController(PermissionManager *pm) : m_permManager(pm) {}
    void requestWriteAccess(const QString &reason) {
        auto decision = m_permManager->requestPermission(Permission::WriteDocument, reason);
        if (decision == PermissionManager::Decision::Granted) performWrite();
    }
private:
    void performWrite() {}
    PermissionManager *m_permManager;
};

class PluginActions : public QObject {
    Q_OBJECT
public:
    explicit PluginActions(KTextEditor::MainWindow *mainWindow, PermissionManager *pm)
        : QObject(mainWindow), m_mainWindow(mainWindow), m_permManager(pm) {
        auto *action = m_mainWindow->actionCollection()->addAction("write");
        connect(action, &KAction::triggered, this, &PluginActions::onWriteRequested);
    }
private slots:
    void onWriteRequested() {
        if (!m_permManager->hasPermission(Permission::WriteDocument)) {
            m_permManager->requestPermission(Permission::WriteDocument, "Needs write access"); return;
        }
        performWrite();
    }
    void performWrite() {}
private:
    KTextEditor::MainWindow *m_mainWindow; PermissionManager *m_permManager;
};
```

## Testing C++ Plugins

```cpp
#include <QTest>
#include <QObject>

class DocumentHandlerTest : public QObject {
    Q_OBJECT
private slots:
    void testInsertText() {
        KTextEditor::Document *doc = new KTextEditor::Document(nullptr);
        DocumentHandler handler(doc);
        handler.insertText(KTextEditor::Cursor(0, 0), "Hello");
        QCOMPARE(doc->text(), QString("Hello"));
        delete doc;
    }
    void testReplaceText() {
        KTextEditor::Document *doc = new KTextEditor::Document(nullptr);
        doc->setText("Hello World");
        DocumentHandler handler(doc);
        handler.replaceText(KTextEditor::Range(0, 0, 0, 5), "Hi");
        QCOMPARE(doc->text(), QString("Hi World"));
        delete doc;
    }
};
QTEST_APPLESS_MAIN(DocumentHandlerTest)
#include "test_document_handler.moc"

class MockDocument : public QObject {
    Q_OBJECT
public:
    QString text() const { return m_text; }
    void setText(const QString &t) { m_text = t; }
    void insertText(const KTextEditor::Cursor &, const QString &text) { m_text += text; emit textChanged(this); }
signals:
    void textChanged(KTextEditor::Document *doc);
private:
    QString m_text;
};

class AgentThreadTest : public QObject {
    Q_OBJECT
private slots:
    void testTaskProcessing() {
        AgentThread thread; thread.start();
        bool completed = false;
        connect(&thread, &AgentThread::taskCompleted, [&completed](const QString &, const QString &) { completed = true; });
        thread.enqueueTask("test-task");
        QTest::qWait(1000);
        QVERIFY(completed);
        thread.quit(); thread.wait();
    }
};
QTEST_MAIN(AgentThreadTest)
#include "test_agent_thread.moc"

enable_testing()
find_package(Qt5 REQUIRED COMPONENTS Test)
add_executable(test_myplugin test_main.cpp test_document_handler.cpp test_agent_thread.cpp)
target_link_libraries(test_myplugin PRIVATE Qt5::Test KF5::KTextEditor myplugin)
add_test(NAME myplugin_tests COMMAND test_myplugin)
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Plugin not loading | Verify metadata.json and KPluginFactory |
| KTextEditor symbols undefined | Link KF5::KTextEditor |
| Signal/slot not connecting | Ensure Q_OBJECT and moc |
| Crash on addView | Check null view/document |
| Config not persisting | Call KConfigGroup::sync() |
| Thread safety issues | Use Qt::QueuedConnection |
| AgentLoop tasks stuck | Verify task queue and signals |
| Permission requests hanging | Implement async callback |

## Best Practices

- Use Q_PLUGIN_METADATA with JSON file for registration
- Always check for null pointers on view/document
- Use Qt::QueuedConnection for cross-thread signals
- Implement cleanup in removeView() matching addView()
- Store config in KConfig with namespaced groups
- Use smart pointers for interface-based DI
- Process long tasks in worker threads
- Emit results via queued signals for UI updates
- Use QTest with mock KTextEditor interfaces
- Follow KDE coding style

## References

- **KTextEditor API**: https://docs.kde.org/stable5/kservice/ktexteditor/
- **KPluginFactory**: https://doc.qt.io/qt-5/qpluginfactory.html
- **KDE Frameworks**: https://kde.org/products/frameworks/
- **Kate Developer**: https://kate-editor.org/development/
- **ECM**: https://community.kde.org/Frameworks/ECM
- **Qt Docs**: https://doc.qt.io/qt-5/
- **KConfig**: https://api.kde.org/frameworks/kconfig/html/
