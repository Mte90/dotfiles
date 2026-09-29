This reference file is loaded on demand from ../SKILL.md.

# QML Integration

## Exposing C++ Objects to QML

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

## QML File

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

## Q_PROPERTY Attributes

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

## Q_INVOKABLE Methods

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