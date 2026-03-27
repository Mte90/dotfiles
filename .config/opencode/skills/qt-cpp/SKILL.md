---
name: qt-cpp
description: Comprehensive guide for developing cross-platform desktop applications with Qt in C++, including Qt5/Qt6, CMake, signals/slots, widgets, QML, threading, and deployment.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - qt
    - c++
    - gui
    - desktop
    - qt6
    - cmake
    - cross-platform
    - qml
    - threading
---

# Qt C++ Development

Complete reference for building cross-platform desktop applications with Qt framework in C++.

## Overview

Qt is a powerful C++ framework for cross-platform application development. It provides rich GUI capabilities, networking, database access, and more.

**Key Characteristics:**
- Cross-platform (Windows, macOS, Linux, mobile)
- Rich widget library and QML for modern UIs
- Signal-slot mechanism for event handling
- Meta-Object System (MOC) for reflection
- Comprehensive documentation and examples

## Qt Versions

### Qt5 vs Qt6

| Feature | Qt5 | Qt6 |
|---------|-----|-----|
| C++ Standard | C++11 | C++17 minimum |
| Graphics | OpenGL | Vulkan/Metal/DirectX |
| High-DPI | Manual | Enabled by default |
| QString | UTF-16 | UTF-8 by default |
| Status | Maintenance | Active development |

**Use Qt 6 for:** New projects, modern C++17/20 features, better graphics performance

**Use Qt 5 for:** Legacy codebases, Qt 5-only modules, platform constraints

## Installation

### Qt Online Installer (Recommended)

```bash
# Download from https://www.qt.io/download
# Install using the Qt Online Installer
# Select: Qt 6.x, Qt Creator, CMake, MinGW or MSVC
```

### Package Managers

```bash
# macOS (Homebrew)
brew install qt@6
brew install cmake

# Ubuntu/Debian
sudo apt install qt6-base-dev qt6-tools-dev cmake

# Arch Linux
sudo pacman -S qt6-base cmake
```

### Setting PATH

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="/path/to/Qt/6.5.0/gcc_64/bin:$PATH"
export CMAKE_PREFIX_PATH="/path/to/Qt/6.5.0/gcc_64:$CMAKE_PREFIX_PATH"
```

## CMake Build System

### Basic CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyQtApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)

set(PROJECT_SOURCES
    main.cpp
    mainwindow.cpp
)

set(PROJECT_HEADERS
    mainwindow.h
)

set(PROJECT_FORMS
    mainwindow.ui
)

add_executable(MyQtApp
    ${PROJECT_SOURCES}
    ${PROJECT_HEADERS}
    ${PROJECT_FORMS}
)

target_link_libraries(MyQtApp
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
)
```

### Advanced CMake Configuration

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyQtApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt configuration
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC_OPTIONS "-binary")

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Network
    Sql
    Xml
    Concurrent
)

# Find optional components
find_package(Qt6 QUIET COMPONENTS
    Quick
    QuickControls2
    Qml
    WebEngineWidgets
)

# Source files
set(PROJECT_SOURCES
    src/main.cpp
    src/mainwindow.cpp
    src/settingsdialog.cpp
)

set(PROJECT_HEADERS
    src/mainwindow.h
    src/settingsdialog.h
)

set(PROJECT_FORMS
    ui/mainwindow.ui
    ui/settingsdialog.ui
)

set(PROJECT_QML
    qml/Main.qml
)

set(PROJECT_RESOURCES
    resources/resources.qrc
)

# Create executable
add_executable(MyQtApp
    ${PROJECT_SOURCES}
    ${PROJECT_HEADERS}
    ${PROJECT_FORMS}
    ${PROJECT_QML}
    ${PROJECT_RESOURCES}
)

# Link libraries
target_link_libraries(MyQtApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
    Qt6::Sql
    Qt6::Xml
    Qt6::Concurrent
)

# Optional: Qt Quick
if(TARGET Qt6::Quick)
    target_link_libraries(MyQtApp PRIVATE Qt6::Quick Qt6::Qml)
endif()

# Installation rules
install(TARGETS MyQtApp
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
```

### Building

```bash
mkdir build && cd build
cmake ..
cmake --build .
./MyQtApp
```

## Signals and Slots

### Basic Signal-Slot Connection

```cpp
// sender.h
#include <QObject>
#include <QTimer>

class Sender : public QObject {
    Q_OBJECT
public:
    explicit Sender(QObject *parent = nullptr) : QObject(parent) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout, this, &Sender::timeout);
        m_timer->start(1000);
    }

signals:
    void timeout();
    void progress(int value);

private:
    QTimer *m_timer;
};

// receiver.h
#include <QObject>

class Receiver : public QObject {
    Q_OBJECT
public slots:
    void handleTimeout() {
        qDebug() << "Timeout received!";
    }

    void handleProgress(int value) {
        qDebug() << "Progress:" << value;
    }
};

// main.cpp
int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);

    Sender sender;
    Receiver receiver;

    // Qt5 connection syntax
    QObject::connect(&sender, SIGNAL(timeout()),
                     &receiver, SLOT(handleTimeout()));

    // Qt6 modern connection syntax (recommended)
    QObject::connect(&sender, &Sender::timeout,
                     &receiver, &Receiver::handleTimeout);

    return app.exec();
}
```

### Lambda Connections

```cpp
class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QMainWindow(parent) {
        QPushButton *button = new QPushButton("Click me", this);

        // Lambda with capture
        connect(button, &QPushButton::clicked, this, [this]() {
            handleButtonClick();
        });

        // Lambda with parameters
        connect(button, &QPushButton::clicked, this, [=](bool checked) {
            qDebug() << "Button clicked:" << checked;
        });

        // Lambda with context object
        connect(button, &QPushButton::clicked,
                this, [this]() {
                    this->handleButtonClick();
                },
                Qt::QueuedConnection);
    }

private:
    void handleButtonClick() {
        qDebug() << "Button clicked!";
    }
};
```

### Connection Types

```cpp
// Auto Connection (default)
connect(sender, &Sender::signal, receiver, &Receiver::slot);
// Uses DirectConnection if receiver and sender are in same thread
// Uses QueuedConnection otherwise

// Direct Connection (same thread only)
connect(sender, &Sender::signal, receiver, &Receiver::slot,
        Qt::DirectConnection);
// Slot executes immediately in sender's thread

// Queued Connection (different threads)
connect(sender, &Sender::signal, receiver, &Receiver::slot,
        Qt::QueuedConnection);
// Slot executes in receiver's thread event loop

// Unique Connection (prevents duplicates)
connect(sender, &Sender::signal, receiver, &Receiver::slot,
        Qt::UniqueConnection);

// Blocking Queued Connection (blocks sender until slot finishes)
connect(sender, &Sender::signal, receiver, &Receiver::slot,
        Qt::BlockingQueuedConnection);
```

### Signal Forwarding

```cpp
class Relay : public QObject {
    Q_OBJECT
public:
    explicit Relay(QObject *parent = nullptr) : QObject(parent) {}

    // Relay signals
    void relaySignal(int value) {
        emit forwarded(value);
    }

signals:
    void forwarded(int value);
};

// Usage
Source source;
Relay relay;
Destination dest;

connect(&source, &Source::data, &relay, &Relay::relaySignal);
connect(&relay, &Relay::forwarded, &dest, &Destination::handleData);
```

## Threading

### QThread

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

### QThreadPool and QRunnable

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

### QtConcurrent

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

### moveToThread

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

## QML Integration

### Exposing C++ Objects to QML

```cpp
// dataobject.h
#include <QObject>
#include <QString>

class DataObject : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged)

public:
    explicit DataObject(QObject *parent = nullptr)
        : QObject(parent), m_value(0) {}

    QString name() const { return m_name; }
    void setName(const QString &name) {
        if (m_name != name) {
            m_name = name;
            emit nameChanged();
        }
    }

    int value() const { return m_value; }
    void setValue(int value) {
        if (m_value != value) {
            m_value = value;
            emit valueChanged();
        }
    }

    Q_INVOKABLE void reset() {
        setName("");
        setValue(0);
    }

signals:
    void nameChanged();
    void valueChanged();

private:
    QString m_name;
    int m_value;
};

// main.cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Register type
    qmlRegisterType<DataObject>("MyApp", 1, 0, "DataObject");

    // Or expose instance
    DataObject *obj = new DataObject(&app);
    obj->setName("Test");
    engine.rootContext()->setContextProperty("dataObject", obj);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

    return app.exec();
}
```

### QML File

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import MyApp 1.0

ApplicationWindow {
    width: 400
    height: 300
    visible: true
    title: "Qt Quick Example"

    Column {
        anchors.centerIn: parent
        spacing: 10

        TextField {
            id: nameField
            placeholderText: "Enter name"
            text: dataObject.name
            onTextChanged: dataObject.name = text
        }

        SpinBox {
            value: dataObject.value
            onValueChanged: dataObject.value = value
        }

        Button {
            text: "Reset"
            onClicked: dataObject.reset()
        }

        Text {
            text: dataObject.name + " - " + dataObject.value
        }
    }
}
```

### Q_PROPERTY Attributes

```cpp
class Person : public QObject {
    Q_OBJECT
    // READ: getter method
    // WRITE: setter method (optional)
    // NOTIFY: signal emitted when value changes
    // CONSTANT: value never changes
    // FINAL: property cannot be overridden
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged CONSTANT FINAL)
    Q_PROPERTY(int age READ age WRITE setAge NOTIFY ageChanged)

public:
    QString name() const { return m_name; }
    void setName(const QString &name) {
        if (m_name != name) {
            m_name = name;
            emit nameChanged();
        }
    }

    int age() const { return m_age; }
    void setAge(int age) {
        if (m_age != age) {
            m_age = age;
            emit ageChanged();
        }
    }

signals:
    void nameChanged();
    void ageChanged();

private:
    QString m_name;
    int m_age;
};
```

### Q_INVOKABLE Methods

```cpp
class Utility : public QObject {
    Q_OBJECT
public:
    explicit Utility(QObject *parent = nullptr) : QObject(parent) {}

    // Can be called from QML
    Q_INVOKABLE QString reverse(const QString &text) {
        QString reversed;
        for (int i = text.length() - 1; i >= 0; --i) {
            reversed += text[i];
        }
        return reversed;
    }

    Q_INVOKABLE void log(const QString &message) {
        qDebug() << "QML:" << message;
    }
};
```

## Model/View Programming

### QAbstractListModel

```cpp
#include <QAbstractListModel>
#include <QVector>

class TodoModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        TextRole = Qt::UserRole + 1,
        DoneRole
    };

    explicit TodoModel(QObject *parent = nullptr)
        : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        Q_UNUSED(parent);
        return m_todos.size();
    }

    QVariant data(const QModelIndex &index, int role) const override {
        if (!index.isValid() || index.row() >= m_todos.size())
            return QVariant();

        const Todo &todo = m_todos[index.row()];

        switch (role) {
        case TextRole:
            return todo.text;
        case DoneRole:
            return todo.done;
        default:
            return QVariant();
        }
    }

    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roles;
        roles[TextRole] = "text";
        roles[DoneRole] = "done";
        return roles;
    }

    Q_INVOKABLE void add(const QString &text) {
        beginInsertRows(QModelIndex(), m_todos.size(), m_todos.size());
        m_todos.append({text, false});
        endInsertRows();
    }

    Q_INVOKABLE void remove(int index) {
        if (index < 0 || index >= m_todos.size())
            return;

        beginRemoveRows(QModelIndex(), index, index);
        m_todos.removeAt(index);
        endRemoveRows();
    }

    Q_INVOKABLE void toggle(int index) {
        if (index < 0 || index >= m_todos.size())
            return;

        m_todos[index].done = !m_todos[index].done;
        emit dataChanged(createIndex(index, 0),
                        createIndex(index, 0),
                        {DoneRole});
    }

private:
    struct Todo {
        QString text;
        bool done;
    };

    QVector<Todo> m_todos;
};
```

### QML ListView with Model

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15

ListView {
    width: 400
    height: 500
    model: todoModel
    delegate: ItemDelegate {
        width: ListView.view.width
        height: 50

        CheckBox {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            checked: model.done
            onClicked: todoModel.toggle(index)
        }

        Text {
            anchors.left: checkbox.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: model.text
            elide: Text.ElideRight
        }
    }

    Button {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        text: "Add"
        onClicked: todoModel.add("New todo")
    }
}
```

## Qt 6 Specific Features

### QString UTF-8 by Default

```cpp
// Qt5: UTF-16
QString text = "Hello";  // Internally UTF-16
QByteArray bytes = text.toUtf8();  // Need explicit conversion

// Qt6: UTF-8 by default
QString text = "Hello";  // Internally UTF-8
QByteArray bytes = text.toLatin1();  // Need explicit conversion for Latin-1
```

### New Graphics Stack

```cpp
// Qt6 uses RHI (Rendering Hardware Interface)
// Supports Vulkan, Metal, Direct3D 11/12, OpenGL

// For Qt Quick 3D
import QtQuick3D 6.0

Model {
    id: cube
    source: "#Cube"
    scale: Qt.vector3d(2, 2, 2)
}

Node {
    Model {
        id: sceneModel
        source: "#Rectangle"
        scale: Qt.vector3d(10, 10, 1)
        materials: PrincipledMaterial {
            baseColor: "green"
        }
    }
}
```

### Properties

```cpp
// Qt6 properties (similar to Q_PROPERTY but simpler)
class Counter : public QObject {
    Q_OBJECT
    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged FINAL)

    QML_ELEMENT  // Register for QML

public:
    int value() const { return m_value; }
    void setValue(int value) {
        if (m_value != value) {
            m_value = value;
            emit valueChanged();
        }
    }

    // Property binding (Qt6 feature)
    Q_PROPERTY(int doubled READ doubled NOTIFY valueChanged FINAL)
    int doubled() const { return m_value * 2; }

signals:
    void valueChanged();

private:
    int m_value = 0;
};
```

## Deployment

### Windows (windeployqt)

```bash
# Build release
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Deploy
windeployqt.exe --release MyQtApp.exe

# With plugins
windeployqt.exe --release --no-translations MyQtApp.exe

# With OpenSSL (if using QtNetwork with SSL)
windeployqt.exe --release --no-translations MyQtApp.exe
xcopy /E /I /Y C:\OpenSSL\*.dll deploy
```

### macOS (macdeployqt)

```bash
# Build release
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Deploy
macdeployqt MyQtApp.app -dmg

# With frameworks
macdeployqt MyQtApp.app -verbose=3

# Code sign (requires developer certificate)
codesign --deep --force --verify --verbose \
  MyQtApp.app

# Create DMG
hdiutil create -volname "MyQtApp" -srcfolder MyQtApp.app \
  -ov -format UDZO MyQtApp.dmg
```

### Linux (linuxdeployqt)

```bash
# Install linuxdeployqt
wget https://github.com/linuxdeploy/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
chmod +x linuxdeployqt-continuous-x86_64.AppImage

# Build release
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Deploy
./linuxdeployqt-continuous-x86_64.AppImage MyQtApp

# Create AppImage
./linuxdeployqt-continuous-x86_64.AppImage \
  --appdir AppDir \
  --output appimage
```

### CMake Installation Rules

```cmake
# Platform-specific installation
if(WIN32)
    install(TARGETS MyQtApp
        RUNTIME DESTINATION .
    )

    # Deploy with windeployqt
    install(CODE
        "${CMAKE_COMMAND}" -E env "PATH=$ENV{PATH}"
        "${CMAKE_PREFIX_PATH}/bin/windeployqt.exe"
        --dir "${CMAKE_INSTALL_PREFIX}"
        --no-translations
        MyQtApp.exe
    )
elseif(APPLE)
    install(TARGETS MyQtApp
        BUNDLE DESTINATION .
    )

    # Deploy with macdeployqt
    install(CODE
        execute_process(COMMAND ${CMAKE_PREFIX_PATH}/bin/macdeployqt
            "${CMAKE_INSTALL_PREFIX}/MyQtApp.app"
            -dmg)
    )
else()
    install(TARGETS MyQtApp
        RUNTIME DESTINATION bin
    )

    # Desktop file
    install(FILES MyQtApp.desktop
        DESTINATION share/applications)

    # Icons
    install(FILES icons/myqtapp.png
        DESTINATION share/icons/hicolor/256x256/apps)
endif()
```

## Common Issues and Solutions

### Memory Leaks

**Problem:** QObject children not deleted correctly

```cpp
// ❌ BAD: Manual deletion can cause issues
delete myWidget;  // May crash if parent still exists

// ✅ GOOD: Use deleteLater() or parent-child system
myWidget->deleteLater();
// Or
myWidget->setParent(nullptr);
delete myWidget;
```

### Thread Safety

**Problem:** GUI updates from wrong thread

```cpp
// ❌ BAD: Updating UI from worker thread
class Worker : public QObject {
    void run() {
        label->setText("Done");  // CRASH!
    }
};

// ✅ GOOD: Use signals to update UI
class Worker : public QObject {
    void run() {
        emit updateText("Done");  // Safe
    }

signals:
    void updateText(const QString &text);
};

connect(worker, &Worker::updateText,
        label, &QLabel::setText,
        Qt::QueuedConnection);
```

### Signal-Slot Connection Issues

**Problem:** Signals not connected

```cpp
// ❌ BAD: Using old syntax in Qt6
connect(sender, SIGNAL(valueChanged(int)),
        receiver, SLOT(handleValue(int)));

// ✅ GOOD: Use modern syntax
connect(sender, &Sender::valueChanged,
        receiver, &Receiver::handleValue);

// ✅ GOOD: Runtime check
if (!connect(sender, &Sender::valueChanged,
              receiver, &Receiver::handleValue)) {
    qWarning() << "Failed to connect signal";
}
```

### QML Binding Issues

**Problem:** Properties not updating in QML

```cpp
// ❌ BAD: Forgetting NOTIFY
class Counter : public QObject {
    Q_PROPERTY(int value READ value WRITE setValue)  // Missing NOTIFY
};

// ✅ GOOD: Always include NOTIFY for writable properties
class Counter : public QObject {
    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged)
    void setValue(int value) {
        if (m_value != value) {
            m_value = value;
            emit valueChanged();  // Must emit!
        }
    }
signals:
    void valueChanged();
};
```

### Build Errors

**Problem:** MOC not running

```cmake
# ❌ BAD: Missing AUTOMOC
add_executable(MyQtApp main.cpp mainwindow.cpp)
target_link_libraries(MyQtApp Qt6::Widgets)

# ✅ GOOD: Enable AUTOMOC
set(CMAKE_AUTOMOC ON)
add_executable(MyQtApp main.cpp mainwindow.cpp)
target_link_libraries(MyQtApp Qt6::Widgets)
```

### Deployment Issues

**Problem:** Missing plugins on target system

```bash
# Windows: Missing DLLs
windeployqt.exe MyQtApp.exe --verbose

# macOS: Missing frameworks
macdeployqt MyQtApp.app --verbose=3

# Linux: Missing libraries
ldd ./MyQtApp  # Check dependencies
```

## Best Practices

1. **Always use Qt6 for new projects**
2. **Prefer modern signal-slot syntax** (`&Sender::signal`)
3. **Use `deleteLater()` instead of `delete`** for QObjects
4. **Enable `AUTOMOC`, `AUTOUIC`, `AUTORCC`** in CMake
5. **Use Q_PROPERTY for properties exposed to QML**
6. **Avoid blocking operations in main thread**
7. **Use `moveToThread()` for worker objects**
8. **Test on all target platforms early**
9. **Use Qt Creator's visual editors** for UI design
10. **Leverage Qt's extensive documentation and examples**

## Resources

- **Official Documentation:** https://doc.qt.io/qt-6/
- **Qt Wiki:** https://wiki.qt.io/
- **Qt Forum:** https://forum.qt.io/
- **Examples:** https://doc.qt.io/qt-6/examples-and-tutorials.html
- **Qt Creator:** https://www.qt.io/product/development-tools
- **Qt Project Hosting:** https://codereview.qt-project.org/

## Quick Reference

### Common Headers

```cpp
#include <QApplication>      // GUI application
#include <QMainWindow>      // Main window
#include <QWidget>          // Basic widget
#include <QPushButton>      // Button
#include <QLabel>           // Text label
#include <QLineEdit>        // Text input
#include <QVBoxLayout>      // Layout
#include <QTimer>           // Timer
#include <QThread>          // Threading
#include <QNetworkAccessManager>  // Network
#include <QSqlDatabase>     // Database
```

### Common CMake Components

```cmake
find_package(Qt6 REQUIRED COMPONENTS
    Core        # Core non-GUI functionality
    Gui         # Window system, events
    Widgets     # UI widgets
    Network     # Network programming
    Sql         # SQL database
    Xml         # XML/SAX/DOM parsers
    Concurrent  # Threading utilities
)
```

### Common Qt6 Modules

- **Qt6::Core** - Core functionality
- **Qt6::Gui** - Windowing, events, 2D graphics
- **Qt6::Widgets** - UI widgets
- **Qt6::Quick** - QML framework
- **Qt6::Network** - Network APIs
- **Qt6::Sql** - SQL database
- **Qt6::Xml** - XML processing
- **Qt6::Test** - Unit testing framework
- **Qt6::Concurrent** - Threading utilities
