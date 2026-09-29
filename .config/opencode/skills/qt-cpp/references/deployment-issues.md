This reference file is loaded on demand from ../SKILL.md.

# Deployment and Common Issues

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