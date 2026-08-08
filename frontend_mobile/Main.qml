import QtQuick
import QtQuick.Controls

Window {
    width: 360
    height: 640
    visible: true
    title: "UniApp"
    color: "#1C2128"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "LoginScreen.qml"
    }
}