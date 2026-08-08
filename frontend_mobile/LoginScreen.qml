import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UniApp.Backend

Page {
    id: loginPage
    background: Rectangle { color: "#1C2128" }

    Connections {
        target: AuthManager

        function onLoginSuccess(userName, userInfo, gradesInfo, dormStatus) {
            errorLabel.visible = false
            loginPage.StackView.view.push("DashboardScreen.qml", {
                studentName: userName,
                studentInfo: userInfo,
                gradesData: gradesInfo,
                dormInfo: dormStatus
            })
        }

        function onLoginError(errorMessage) {
            errorLabel.text = errorMessage
            errorLabel.visible = true
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.85
        spacing: 20

        Label {
            text: "UniApp"
            color: "#FFFFFF"
            font.pixelSize: 42
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Make it easy."
            color: "#0056A4"
            font.pixelSize: 16
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
        }

        TextField {
            id: facultyField
            placeholderText: "Факультетный номер"
            placeholderTextColor: "#8B949E"
            color: "#FFFFFF"
            font.pixelSize: 16
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            leftPadding: 15
            background: Rectangle {
                color: "#22272E"
                radius: 8
                border.width: 2
                border.color: facultyField.activeFocus ? "#0056A4" : "#373E47"
            }
        }

        TextField {
            id: authCodeField
            placeholderText: "2FA / ЕГН / ЛНЧ"
            placeholderTextColor: "#8B949E"
            echoMode: TextInput.Password
            color: "#FFFFFF"
            font.pixelSize: 16
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            leftPadding: 15
            background: Rectangle {
                color: "#22272E"
                radius: 8
                border.width: 2
                border.color: authCodeField.activeFocus ? "#0056A4" : "#373E47"
            }
        }

        Label {
            id: errorLabel
            color: "#ef4444"
            visible: false
            font.pixelSize: 14
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            text: AuthManager.isLoading ? "Авторизация..." : "Войти"
            enabled: !AuthManager.isLoading
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.topMargin: 10

            contentItem: Text {
                text: parent.text
                color: "#FFFFFF"
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.pressed ? "#004482" : (parent.hovered ? "#0068C6" : "#0056A4")
                radius: 8
            }

            onClicked: {
                errorLabel.visible = false
                AuthManager.login(facultyField.text, authCodeField.text)
            }
        }
    }
}