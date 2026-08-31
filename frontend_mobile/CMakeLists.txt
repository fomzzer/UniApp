cmake_minimum_required(VERSION 3.16)

project(uniapp_mobile VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

set_source_files_properties(Assets.xcassets PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

qt_add_executable(appuniapp_mobile
    main.cpp
    Assets.xcassets
)

qt_add_qml_module(appuniapp_mobile
    URI uniapp_mobile
    QML_FILES
        Main.qml
        LoginScreen.qml
        DashboardScreen.qml
    SOURCES
        authmanager.h
        authmanager.cpp
)

set_target_properties(appuniapp_mobile PROPERTIES
    OUTPUT_NAME "UniApp"

    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"

    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.fomzzer.uniapp"
    MACOSX_BUNDLE_BUNDLE_NAME "UniApp"
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}

    XCODE_ATTRIBUTE_INFOPLIST_KEY_CFBundleDisplayName "UniApp"
    XCODE_ATTRIBUTE_PRODUCT_NAME "UniApp"

    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"

    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appuniapp_mobile
    PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network Qt6::QuickControls2
)

install(TARGETS appuniapp_mobile
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (ANDROID)
    include(${CMAKE_CURRENT_SOURCE_DIR}/android_openssl/android_openssl.cmake)
    add_android_openssl_libraries(appuniapp_mobile)
endif()