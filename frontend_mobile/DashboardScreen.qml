import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf
import UniApp.Backend

Page {
    id: dashboardPage
    background: Rectangle { color: "#1C2128" }

    property string studentName: ""
    property var studentInfo: ({})
    property var gradesData: []
    property string dormInfo: ""
    property string currentPdfUrl: ""

    Connections {
        target: AuthManager
        function onScheduleUrlReceived(pdfUrl) {
            dashboardPage.currentPdfUrl = pdfUrl;
        }
        function onScheduleError(errorMessage) {
            dashboardPage.currentPdfUrl = "";
            scheduleStatusLabel.text = errorMessage;
            scheduleStatusLabel.color = "#ef4444";
        }
    }

    PdfDocument {
        id: schedulePdf
        source: dashboardPage.currentPdfUrl
    }

    function getCourse(semesterStr) {
        let sem = parseInt(semesterStr);
        if (isNaN(sem)) return "-";
        return Math.floor((sem + 1) / 2);
    }

    function getField(item, keywords) {
        if (!item) return "-";
        for (let i = 0; i < keywords.length; i++) {
            let k = keywords[i].toLowerCase();
            for (let prop in item) {
                if (prop.toLowerCase().indexOf(k) !== -1) {
                    let val = item[prop];
                    if (val !== undefined && val !== null && val !== "") return val;
                }
            }
        }
        return "-";
    }

    function getGradeText(item) {
        if (!item) return "-";
        if (item["final"] && item["final"] !== "-") return item["final"];
        if (item["regular"] && item["regular"] !== "-") return item["regular"];
        if (item["retake"] && item["retake"] !== "-") return item["retake"];
        return "-";
    }

    function getGradeColor(gradeText) {
        if (!gradeText || gradeText === "-") return "#1F6FEB";
        if (gradeText.indexOf("6") !== -1 || gradeText.indexOf("Зачита се") !== -1) return "#1e6823";
        if (gradeText.indexOf("5") !== -1) return "#2ea043";
        if (gradeText.indexOf("4") !== -1) return "#d29922";
        if (gradeText.indexOf("3") !== -1) return "#e36209";
        if (gradeText.indexOf("2") !== -1) return "#da3633";
        return "#1F6FEB";
    }

    function calculateGPA() {
        if (!gradesData || gradesData.length === 0) return "0.00";
        let sum = 0;
        let count = 0;
        for (let i = 0; i < gradesData.length; i++) {
            let item = gradesData[i];
            if (item["is_semester"]) continue;
            let text = getGradeText(item);
            let match = text.match(/\d/);
            if (match) {
                sum += parseInt(match[0]);
                count++;
            }
        }
        return count > 0 ? (sum / count).toFixed(2) : "0.00";
    }

    function getProcessedGrades() {
        if (!gradesData || gradesData.length === 0) return [];

        let semesters = [];
        let currentSem = null;

        for (let idx = 0; idx < gradesData.length; idx++) {
            let item = gradesData[idx];
            if (item["is_semester"] === true) {
                if (currentSem) semesters.push(currentSem);
                currentSem = { header: item, items: [] };
            } else {
                if (!currentSem) currentSem = { header: { is_semester: true, title: "Общи" }, items: [] };

                let subj = getField(item, ["дисциплин", "subject", "предмет", "наименовани", "name", "title"]);
                let gradeText = getGradeText(item);

                let existingIdx = -1;
                for (let i = 0; i < currentSem.items.length; i++) {
                    if (getField(currentSem.items[i], ["дисциплин", "subject", "предмет", "наименовани", "name", "title"]) === subj) {
                        existingIdx = i;
                        break;
                    }
                }

                if (existingIdx !== -1) {
                    let existingGrade = getGradeText(currentSem.items[existingIdx]);
                    if (existingGrade === "Зачита се" || existingGrade === "-") {
                        if (gradeText !== "-" && gradeText !== "Зачита се") {
                            currentSem.items[existingIdx] = item;
                        }
                    }
                } else {
                    currentSem.items.push(item);
                }
            }
        }
        if (currentSem) semesters.push(currentSem);

        semesters.sort((a, b) => {
            let titleA = a.header.title ? a.header.title.toString() : "";
            let titleB = b.header.title ? b.header.title.toString() : "";
            let numA = parseInt(titleA.replace(/\D/g, '')) || 0;
            let numB = parseInt(titleB.replace(/\D/g, '')) || 0;
            return numB - numA;
        });

        let flatResult = [];
        for (let idxA = 0; idxA < semesters.length; idxA++) {
            flatResult.push(semesters[idxA].header);
            for (let idxB = 0; idxB < semesters[idxA].items.length; idxB++) {
                flatResult.push(semesters[idxA].items[idxB]);
            }
        }
        return flatResult;
    }

    function getAcronym(str) {
        if (!str || str === "-") return "-";
        let words = str.toString().trim().split(/[\s-]+/);
        let acronym = "";
        let stopWords = ["по", "и", "в", "на", "за", "с", "от"];
        for (let i = 0; i < words.length; i++) {
            let w = words[i].toLowerCase();
            if (stopWords.indexOf(w) === -1 && w.length > 0) {
                acronym += w.charAt(0).toUpperCase();
            }
        }
        return acronym.length > 0 ? acronym : str;
    }

    function getUniqueList(defaultValue, defaultList) {
        let val = (defaultValue !== undefined && defaultValue !== null) ? defaultValue.toString().trim() : "";
        let list = [];
        if (val !== "" && val !== "-") {
            list.push(val);
        }
        for (let i = 0; i < defaultList.length; i++) {
            if (defaultList[i] !== val) {
                list.push(defaultList[i]);
            }
        }
        if (list.length === 0) return defaultList;
        return list;
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        Page {
            background: Rectangle { color: "transparent" }
            clip: true

            ListView {
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: 1

                delegate: Item {
                    width: parent.width
                    height: profileCol.implicitHeight + 40

                    ColumnLayout {
                        id: profileCol
                        width: parent.width * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        spacing: 20

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
        }

        Page {
            background: Rectangle { color: "transparent" }
            clip: true

            Label {
                anchors.centerIn: parent
                text: "Нет данных об оценках"
                color: "#8B949E"
                font.pixelSize: 16
                visible: dashboardPage.gradesData.length === 0
            }

            ListView {
                id: gradesListView
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: dashboardPage.getProcessedGrades()
                spacing: 8

                header: Item {
                    width: parent.width
                    height: 80
                    visible: dashboardPage.gradesData.length > 0

                    Rectangle {
                        width: parent.width * 0.9
                        height: 50
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 5
                        color: "#22272E"
                        radius: 12
                        border.color: "#373E47"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Label {
                                text: "Среден успех (GPA)"
                                color: "#8B949E"
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.minimumWidth: 45
                                Layout.preferredWidth: Math.max(45, gpaValLabel.implicitWidth + 16)
                                Layout.preferredHeight: 30
                                radius: 6
                                color: dashboardPage.getGradeColor(dashboardPage.calculateGPA())

                                Label {
                                    id: gpaValLabel
                                    anchors.centerIn: parent
                                    text: dashboardPage.calculateGPA()
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                footer: Item { width: parent.width; height: 40 }

                delegate: Loader {
                    width: parent ? parent.width * 0.9 : 300
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    sourceComponent: modelData["is_semester"] === true ? headerComponent : gradeComponent

                    Component {
                        id: headerComponent
                        Item {
                            width: parent.width
                            height: 45
                            Label {
                                text: modelData["title"] || ""
                                color: "#58A6FF"
                                font.pixelSize: 16
                                font.bold: true
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                            }
                        }
                    }

                    Component {
                        id: gradeComponent
                        Rectangle {
                            width: parent.width
                            height: gradeCol.implicitHeight + 24
                            color: "#22272E"
                            radius: 12
                            border.color: "#373E47"
                            border.width: 1

                            ColumnLayout {
                                id: gradeCol
                                anchors.centerIn: parent
                                width: parent.width - 24
                                spacing: 8

                                Label {
                                    text: dashboardPage.getField(modelData, ["дисциплин", "subject", "предмет", "наименовани", "name", "title"])
                                    color: "#FFFFFF"
                                    font.pixelSize: 15
                                    font.bold: true
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#373E47"
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: {
                                            let t = modelData["type"] || "";
                                            let g = dashboardPage.getGradeText(modelData);
                                            return (t === "Зачита се" || t === g || t === "-") ? "" : t;
                                        }
                                        color: "#8B949E"
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Rectangle {
                                        Layout.minimumWidth: 45
                                        Layout.preferredWidth: Math.max(45, gradeValLabel.implicitWidth + 16)
                                        Layout.preferredHeight: 30
                                        radius: 6
                                        color: dashboardPage.getGradeColor(dashboardPage.getGradeText(modelData))

                                        Label {
                                            id: gradeValLabel
                                            anchors.centerIn: parent
                                            text: dashboardPage.getGradeText(modelData)
                                            color: "#FFFFFF"
                                            font.pixelSize: 14
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Page {
            background: Rectangle { color: "transparent" }
            clip: true

            ListView {
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: 1

                delegate: Item {
                    width: parent.width
                    height: scheduleLayout.implicitHeight + 40

                    ColumnLayout {
                        id: scheduleLayout
                        width: parent.width * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        spacing: 20

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: filterContent.implicitHeight + 40
                            color: "#22272E"
                            radius: 12
                            border.color: "#373E47"
                            border.width: 1

                            ColumnLayout {
                                id: filterContent
                                anchors.centerIn: parent
                                width: parent.width - 30
                                spacing: 15

                                Label {
                                    text: "Параметры расписания"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                    Layout.bottomMargin: 5
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Label { text: "Факультет"; color: "#8B949E"; font.pixelSize: 13 }
                                    ComboBox {
                                        id: comboFac
                                        Layout.fillWidth: true
                                        model: dashboardPage.getUniqueList(dashboardPage.getAcronym(studentInfo["Факултет"]), ["ФИТ", "ФКСТ", "ФЕЕ", "МФ", "ФТК", "ФА", "СФ"])

                                        background: Rectangle {
                                            implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                        }
                                        contentItem: Text {
                                            text: parent.displayText; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10; elide: Text.ElideRight
                                        }
                                        delegate: ItemDelegate {
                                            width: comboFac.width; height: 40
                                            contentItem: Text { text: modelData; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                            background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                        }
                                        popup: Popup {
                                            y: comboFac.height - 1; width: comboFac.width; padding: 1
                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: comboFac.popup.visible ? comboFac.delegateModel : null
                                                currentIndex: comboFac.highlightedIndex
                                            }
                                            background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Label { text: "Специальность"; color: "#8B949E"; font.pixelSize: 13 }
                                    ComboBox {
                                        id: comboSpec
                                        Layout.fillWidth: true
                                        model: dashboardPage.getUniqueList(dashboardPage.getAcronym(studentInfo["Специалност"]), ["ИСИИ", "КСИ", "ИТ", "КСТ"])

                                        background: Rectangle {
                                            implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                        }
                                        contentItem: Text {
                                            text: parent.displayText; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10; elide: Text.ElideRight
                                        }
                                        delegate: ItemDelegate {
                                            width: comboSpec.width; height: 40
                                            contentItem: Text { text: modelData; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                            background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                        }
                                        popup: Popup {
                                            y: comboSpec.height - 1; width: comboSpec.width; padding: 1
                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: comboSpec.popup.visible ? comboSpec.delegateModel : null
                                                currentIndex: comboSpec.highlightedIndex
                                            }
                                            background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 15

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        Label { text: "Курс"; color: "#8B949E"; font.pixelSize: 13 }
                                        ComboBox {
                                            id: comboCourse
                                            Layout.fillWidth: true
                                            model: dashboardPage.getUniqueList(dashboardPage.getCourse(studentInfo["Заверен семестър"]), ["1", "2", "3", "4"])

                                            background: Rectangle {
                                                implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                            }
                                            contentItem: Text {
                                                text: parent.displayText; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10
                                            }
                                            delegate: ItemDelegate {
                                                width: comboCourse.width; height: 40
                                                contentItem: Text { text: modelData; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                            }
                                            popup: Popup {
                                                y: comboCourse.height - 1; width: comboCourse.width; padding: 1
                                                contentItem: ListView {
                                                    clip: true
                                                    implicitHeight: contentHeight
                                                    model: comboCourse.popup.visible ? comboCourse.delegateModel : null
                                                    currentIndex: comboCourse.highlightedIndex
                                                }
                                                background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        Label { text: "Группа"; color: "#8B949E"; font.pixelSize: 13 }
                                        ComboBox {
                                            id: comboGroup
                                            Layout.fillWidth: true
                                            model: dashboardPage.getUniqueList(studentInfo["Група"], ["21", "22", "23", "24", "31", "32"])

                                            background: Rectangle {
                                                implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                            }
                                            contentItem: Text {
                                                text: parent.displayText; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10
                                            }
                                            delegate: ItemDelegate {
                                                width: comboGroup.width; height: 40
                                                contentItem: Text { text: modelData; color: "#FFFFFF"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                            }
                                            popup: Popup {
                                                y: comboGroup.height - 1; width: comboGroup.width; padding: 1
                                                contentItem: ListView {
                                                    clip: true
                                                    implicitHeight: contentHeight
                                                    model: comboGroup.popup.visible ? comboGroup.delegateModel : null
                                                    currentIndex: comboGroup.highlightedIndex
                                                }
                                                background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                            }
                                        }
                                    }
                                }

                                Button {
                                    text: AuthManager.isScheduleLoading ? "Загрузка..." : "Загрузить расписание"
                                    enabled: !AuthManager.isScheduleLoading
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10
                                    Layout.preferredHeight: 45

                                    background: Rectangle {
                                        color: parent.pressed ? "#1557B0" : (parent.enabled ? "#1F6FEB" : "#1b4f9e")
                                        radius: 8
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "#FFFFFF"
                                        font.pixelSize: 15
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        scheduleStatusLabel.text = "Расписание пока не загружено";
                                        scheduleStatusLabel.color = "#8B949E";
                                        dashboardPage.currentPdfUrl = "";
                                        AuthManager.fetchSchedule(comboFac.currentText, comboSpec.currentText, comboCourse.currentText, comboGroup.currentText);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: dashboardPage.currentPdfUrl === "" ? 200 : 500
                            color: dashboardPage.currentPdfUrl === "" ? "transparent" : "#22272E"
                            radius: 12
                            border.color: "#373E47"
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 15
                                visible: dashboardPage.currentPdfUrl === ""

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 50; height: 50; radius: 10
                                    color: "#22272E"
                                    border.color: "#373E47"; border.width: 1
                                    Label {
                                        anchors.centerIn: parent
                                        text: "📅"
                                        font.pixelSize: 24
                                    }
                                }

                                Label {
                                    id: scheduleStatusLabel
                                    text: "Расписание пока не загружено"
                                    color: "#8B949E"
                                    font.pixelSize: 15
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            PdfMultiPageView {
                                anchors.fill: parent
                                anchors.margins: 4
                                document: schedulePdf
                                visible: dashboardPage.currentPdfUrl !== ""

                                BusyIndicator {
                                    anchors.centerIn: parent
                                    running: schedulePdf.status === PdfDocument.Loading
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: "Ошибка при чтении PDF"
                                    color: "#ef4444"
                                    font.pixelSize: 15
                                    visible: schedulePdf.status === PdfDocument.Error
                                }
                            }
                        }
                    }
                }
            }
        }

        Page {
            background: Rectangle { color: "transparent" }
            clip: true

            ListView {
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: 1

                delegate: Item {
                    width: parent.width
                    height: infoLayout.implicitHeight + 40

                    ColumnLayout {
                        id: infoLayout
                        width: parent.width * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 30
                        spacing: 30

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 100; height: 100; radius: 30
                            color: "#2D333B"
                            border.color: "#373E47"; border.width: 2

                            Label {
                                anchors.centerIn: parent
                                text: "U"
                                color: "#58A6FF"
                                font.pixelSize: 48
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5

                            Label {
                                text: "UniApp"
                                color: "#FFFFFF"
                                font.pixelSize: 28
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Label {
                                text: "Версия 1.0.0"
                                color: "#8B949E"
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#373E47"
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Label {
                                text: "Неофициальный клиент для студентов ТУ-София."
                                color: "#C9D1D9"
                                font.pixelSize: 15
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: parent.width
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8
                                Label { text: "Разработчик:"; color: "#8B949E"; font.pixelSize: 15 }
                                Label { text: "fomzzer"; color: "#58A6FF"; font.pixelSize: 15; font.bold: true }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8
                                Label { text: "GitHub:"; color: "#8B949E"; font.pixelSize: 15 }
                                Label {
                                    text: "github.com/fomzzer"
                                    color: "#58A6FF"
                                    font.pixelSize: 15
                                    font.underline: true

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://github.com/fomzzer")
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
                font.pixelSize: 13
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
                font.pixelSize: 13
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
                font.pixelSize: 13
                font.bold: parent.checked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        TabButton {
            text: "Инфо"
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: parent.text
                color: parent.checked ? "#58A6FF" : "#8B949E"
                font.pixelSize: 13
                font.bold: parent.checked
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}