import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: dashboardPage
    background: Rectangle { color: "#1C2128" }

    property string studentName: ""
    property var studentInfo: ({})
    property var gradesData: []
    property string dormInfo: ""

    function getCourse(semesterStr) {
        let sem = parseInt(semesterStr);
        if (isNaN(sem)) return "-";
        return Math.floor((sem + 1) / 2);
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        Page {
            background: Rectangle { color: "transparent" }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Item { Layout.preferredHeight: 10 }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 80; height: 80; radius: 40
                            color: "#2D333B"
                            border.color: "#373E47"; border.width: 2

                            Label {
                                anchors.centerIn: parent
                                text: dashboardPage.studentName !== "" ? dashboardPage.studentName.charAt(0) : "U"
                                color: "#58A6FF"
                                font.pixelSize: 36
                                font.bold: true
                            }
                        }

                        Label {
                            text: dashboardPage.studentName
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.maximumWidth: dashboardPage.width * 0.8
                            Layout.topMargin: 10
                        }

                        Label {
                            text: studentInfo["Фак. номер"] ? "Фак. №: " + studentInfo["Фак. номер"] : ""
                            color: "#8B949E"
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: academicCol.implicitHeight + 30
                        color: "#22272E"
                        radius: 12
                        border.color: "#373E47"; border.width: 1

                        ColumnLayout {
                            id: academicCol
                            anchors.centerIn: parent
                            width: parent.width - 30
                            spacing: 12

                            Label { text: "Учебная информация"; color: "#8B949E"; font.bold: true; font.pixelSize: 12; Layout.bottomMargin: 5 }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Факультет"; color: "#8B949E"; font.pixelSize: 14; Layout.fillWidth: true }
                                Label { text: studentInfo["Факултет"] || "-"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.maximumWidth: 150; wrapMode: Text.WordWrap }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Специальность"; color: "#8B949E"; font.pixelSize: 14; Layout.fillWidth: true }
                                Label { text: studentInfo["Специалност"] || "-"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.maximumWidth: 150; wrapMode: Text.WordWrap }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Курс / Семестр"; color: "#8B949E"; font.pixelSize: 14; Layout.fillWidth: true }
                                Label { text: (studentInfo["Записан семестър"] ? getCourse(studentInfo["Записан семестър"]) + " курс, " + studentInfo["Записан семестър"] + " сем." : "-"); color: "#FFFFFF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Группа / Поток"; color: "#8B949E"; font.pixelSize: 14; Layout.fillWidth: true }
                                Label { text: (studentInfo["Група"] || "-") + " / " + (studentInfo["Поток"] || "-"); color: "#FFFFFF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: extraCol.implicitHeight + 30
                        color: "#22272E"
                        radius: 12
                        border.color: "#373E47"; border.width: 1

                        ColumnLayout {
                            id: extraCol
                            anchors.centerIn: parent
                            width: parent.width - 30
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label { text: "Общежитие"; color: "#8B949E"; font.pixelSize: 14 }
                                Label {
                                    text: dashboardPage.dormInfo !== "" ? dashboardPage.dormInfo : "Нет данных"
                                    color: dashboardPage.dormInfo.indexOf("настанен") !== -1 ? "#22c55e" : "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#373E47"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Почта ТУ"; color: "#8B949E"; font.pixelSize: 14; Layout.fillWidth: true }
                                Label { text: studentInfo["Имейл в ТУ - София"] || "-"; color: "#58A6FF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.maximumWidth: 170; wrapMode: Text.WordWrap }
                            }
                        }
                    }

                    Button {
                        text: "Выйти из аккаунта"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        Layout.bottomMargin: 30
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 45

                        background: Rectangle {
                            color: "transparent"
                            border.color: "#ef4444"
                            border.width: 1
                            radius: 8
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#ef4444"
                            font.pixelSize: 15
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: dashboardPage.StackView.view.pop()
                    }
                }
            }
        }

        Page {
            background: Rectangle { color: "transparent" }
            Label { anchors.centerIn: parent; text: "Здесь будет список оценок"; color: "#8B949E"; font.pixelSize: 18 }
        }

        Page {
            background: Rectangle { color: "transparent" }
            Label { anchors.centerIn: parent; text: "Здесь будет расписание"; color: "#8B949E"; font.pixelSize: 18 }
        }
    }

    footer: TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex
        background: Rectangle {
            color: "#22272E"
            border.color: "#373E47"
            border.width: 1
        }

        TabButton {
            text: "Профиль"
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: parent.text
                color: parent.checked ? "#58A6FF" : "#8B949E"
                font.pixelSize: 15
                font.bold: parent.checked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        TabButton {
            text: "Оценки"
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: parent.text
                color: parent.checked ? "#58A6FF" : "#8B949E"
                font.pixelSize: 15
                font.bold: parent.checked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        TabButton {
            text: "Расписание"
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: parent.text
                color: parent.checked ? "#58A6FF" : "#8B949E"
                font.pixelSize: 15
                font.bold: parent.checked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}