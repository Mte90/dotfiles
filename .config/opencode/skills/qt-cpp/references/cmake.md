This reference file is loaded on demand from ../SKILL.md.

# CMake Build System

## Basic CMakeLists.txt

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

## Advanced CMake Configuration

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

## Building

```bash
mkdir build && cd build
cmake ..
cmake --build .
./MyQtApp
```