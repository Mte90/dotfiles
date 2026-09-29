---
name: qt-cpp
description: Use when developing desktop applications with Qt in C++ - CMake setup, signals and slots, QThread and QtConcurrent, QML integration, model/view programming, Qt5 to Qt6 migration, or windeployqt/macdeployqt/linuxdeployqt deployment
metadata:
  author: mte90
  version: 2.0.0
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

## Deep Dives

Load these reference files for detailed guidance:

- **CMake Build System** — `references/cmake.md` — CMake configuration, find_package, installation rules
- **Threading** — `references/threading.md` — QThread, QThreadPool, QtConcurrent, moveToThread patterns
- **QML Integration** — `references/qml-integration.md` — Exposing C++ to QML, Q_PROPERTY, Q_INVOKABLE
- **Deployment & Issues** — `references/deployment-issues.md` — windeployqt, macdeployqt, linuxdeployqt, common problems

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