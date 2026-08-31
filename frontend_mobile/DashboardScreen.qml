import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import UniApp.Backend

Page {
    id: dashboardPage
    background: Rectangle { color: "#1C2128" }

    property string studentName: ""
    property var studentInfo: ({})
    property var gradesData: []
    property string dormInfo: ""

    property var allSchedules: []
    property string currentPdfUrl: ""
    property string scheduleErrorMsg: ""
    property bool hasScheduleError: false

    function setFoundPdfUrl(url) {
        dashboardPage.currentPdfUrl = url;
        dashboardPage.hasScheduleError = false;
        Qt.callLater(function() {
            scheduleFlickable.contentY = Math.max(0, scheduleFlickable.contentHeight - scheduleFlickable.height);
        });
    }

    Connections {
        target: AuthManager
        function onAllSchedulesReceived(schedulesArray) {
            dashboardPage.allSchedules = schedulesArray;
            dashboardPage.updateFaculties();
            dashboardPage.updateSpecialties();
            dashboardPage.updateCourses();
            dashboardPage.updateStreams();

            dashboardPage.autoSelectSchedule();
        }
        function onScheduleError(errorMessage) {
            dashboardPage.currentPdfUrl = "";
            dashboardPage.scheduleErrorMsg = errorMessage;
            dashboardPage.hasScheduleError = true;
        }
    }

    Component.onCompleted: {
        AuthManager.fetchAllSchedules();
    }

    function getAcronym(text) {
        if (!text) return "";
        let cleanText = text.toString().replace(/-/g, ' ');
        let words = cleanText.split(/\s+/);
        let acronym = "";
        let skipWords = ["по", "и", "на", "за", "в", "с"];
        for (let i = 0; i < words.length; i++) {
            let word = words[i].trim().toLowerCase();
            if (word.length > 0 && skipWords.indexOf(word) === -1) {
                acronym += words[i].charAt(0).toUpperCase();
            }
        }
        return acronym;
    }

    function autoSelectSchedule() {
        if (!studentInfo || Object.keys(studentInfo).length === 0 || !allSchedules || allSchedules.length === 0) return;

        let sFac = studentInfo["Факултет"] || "";
        let sSpec = studentInfo["Специалност"] || "";
        let sCourse = getCourse(studentInfo["Записан семестър"]).toString();
        let sStream = studentInfo["Поток"] || "";

        if (sFac === "" || sSpec === "" || sCourse === "-" || sStream === "") return;

        let facAcronym = getAcronym(sFac);
        let specAcronym = getAcronym(sSpec);

        let bestMatch = null;
        for (let i = 0; i < allSchedules.length; i++) {
            let item = allSchedules[i];
            let itemFac = item.faculty.toString().trim();
            let itemSpec = item.speciality.toString().trim();
            let itemCourse = item.course.toString().trim();
            let itemStream = item.stream.toString().trim();

            let facMatch = (itemFac.toLowerCase() === sFac.toLowerCase() || itemFac === facAcronym);
            let specMatch = (itemSpec.toLowerCase() === sSpec.toLowerCase() || itemSpec === specAcronym);
            let courseMatch = (itemCourse === sCourse);
            let streamMatch = (itemStream === sStream || itemStream.indexOf(sStream) !== -1);

            if (facMatch && specMatch && courseMatch && streamMatch) {
                bestMatch = item;
                break;
            }
        }

        if (bestMatch) {
            let facIdx = comboFac.find(bestMatch.faculty);
            if (facIdx !== -1) {
                comboFac.currentIndex = facIdx;

                let specIdx = comboSpec.find(bestMatch.speciality);
                if (specIdx !== -1) {
                    comboSpec.currentIndex = specIdx;

                    let courseIdx = comboCourse.find(bestMatch.course);
                    if (courseIdx !== -1) {
                        comboCourse.currentIndex = courseIdx;

                        let streamIdx = comboStream.find(bestMatch.stream);
                        if (streamIdx !== -1) {
                            comboStream.currentIndex = streamIdx;
                            setFoundPdfUrl(bestMatch.url);
                        }
                    }
                }
            }
        }
    }

    function updateFaculties() {
        if (allSchedules.length === 0) return;
        let facs = ["Выберите факультет"];
        for (let i = 0; i < allSchedules.length; i++) {
            let f = allSchedules[i].faculty;
            if (f && facs.indexOf(f) === -1) {
                facs.push(f);
            }
        }
        comboFac.model = facs;
        comboFac.currentIndex = 0;

        comboSpec.model = ["Выберите специальность"];
        comboCourse.model = ["Выберите курс"];
        comboStream.model = ["Выберите поток"];
    }

    function updateSpecialties() {
        if (allSchedules.length === 0) return;
        let currentFac = comboFac.currentText;
        let specs = ["Выберите специальность"];

        if (currentFac !== "Выберите факультет" && currentFac !== "Загрузка...") {
            for (let i = 0; i < allSchedules.length; i++) {
                if (allSchedules[i].faculty === currentFac) {
                    let s = allSchedules[i].speciality;
                    if (s && specs.indexOf(s) === -1) {
                        specs.push(s);
                    }
                }
            }
        }
        comboSpec.model = specs;
        comboSpec.currentIndex = 0;
    }

    function updateCourses() {
        if (allSchedules.length === 0) return;
        let currentFac = comboFac.currentText;
        let currentSpec = comboSpec.currentText;
        let crs = ["Выберите курс"];

        if (currentFac !== "Выберите факультет" && currentSpec !== "Выберите специальность" && currentFac !== "Загрузка...") {
            for (let i = 0; i < allSchedules.length; i++) {
                if (allSchedules[i].faculty === currentFac && allSchedules[i].speciality === currentSpec) {
                    let c = allSchedules[i].course;
                    if (c && crs.indexOf(c) === -1) {
                        crs.push(c);
                    }
                }
            }
        }
        comboCourse.model = crs;
        comboCourse.currentIndex = 0;
    }

    function updateStreams() {
        if (allSchedules.length === 0) return;
        let currentFac = comboFac.currentText;
        let currentSpec = comboSpec.currentText;
        let currentCourse = comboCourse.currentText;
        let strms = ["Выберите поток"];

        if (currentFac !== "Выберите факультет" && currentSpec !== "Выберите специальность" && currentCourse !== "Выберите курс" && currentFac !== "Загрузка...") {
            for (let i = 0; i < allSchedules.length; i++) {
                if (allSchedules[i].faculty === currentFac &&
                    allSchedules[i].speciality === currentSpec &&
                    allSchedules[i].course === currentCourse) {
                    let st = allSchedules[i].stream;
                    if (st && strms.indexOf(st) === -1) {
                        strms.push(st);
                    }
                }
            }
        }
        comboStream.model = strms;
        comboStream.currentIndex = 0;
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
                                    Label { text: (studentInfo["Записан семестър"] ? dashboardPage.getCourse(studentInfo["Записан семестър"]) + " / " + studentInfo["Записан семестър"] : "-"); color: "#FFFFFF"; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignRight }
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

            Flickable {
                id: scheduleFlickable
                anchors.fill: parent
                contentHeight: scheduleLayout.implicitHeight + 40
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: true

                Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

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
                                    model: ["Загрузка..."]

                                    onCurrentTextChanged: {
                                        if (currentText !== "" && currentText !== "Загрузка..." && currentText !== "Выберите факультет") {
                                            dashboardPage.updateSpecialties();
                                        }
                                    }

                                    background: Rectangle {
                                        implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                    }
                                    contentItem: Text {
                                        text: parent.displayText
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                        rightPadding: 30
                                    }
                                    delegate: ItemDelegate {
                                        width: comboFac.width; height: 40
                                        contentItem: Text {
                                            text: modelData
                                            color: "#FFFFFF"
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                    }
                                    popup: Popup {
                                        y: comboFac.height - 1; width: comboFac.width; padding: 1
                                        height: Math.min(contentItem.implicitHeight + 2, 250)
                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: comboFac.popup.visible ? comboFac.delegateModel : null
                                            currentIndex: comboFac.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator { }
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
                                    model: ["Загрузка..."]

                                    onCurrentTextChanged: {
                                        if (currentText !== "" && currentText !== "Загрузка..." && currentText !== "Выберите специальность") {
                                            dashboardPage.updateCourses();
                                        }
                                    }

                                    background: Rectangle {
                                        implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                    }
                                    contentItem: Text {
                                        text: parent.displayText
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                        rightPadding: 30
                                    }
                                    delegate: ItemDelegate {
                                        width: comboSpec.width; height: 40
                                        contentItem: Text {
                                            text: modelData
                                            color: "#FFFFFF"
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                    }
                                    popup: Popup {
                                        y: comboSpec.height - 1; width: comboSpec.width; padding: 1
                                        height: Math.min(contentItem.implicitHeight + 2, 250)
                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: comboSpec.popup.visible ? comboSpec.delegateModel : null
                                            currentIndex: comboSpec.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator { }
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
                                    Layout.preferredWidth: 1
                                    spacing: 5
                                    Label { text: "Курс"; color: "#8B949E"; font.pixelSize: 13 }
                                    ComboBox {
                                        id: comboCourse
                                        Layout.fillWidth: true
                                        model: ["Загрузка..."]

                                        onCurrentTextChanged: {
                                            if (currentText !== "" && currentText !== "Загрузка..." && currentText !== "Выберите курс") {
                                                dashboardPage.updateStreams();
                                            }
                                        }

                                        background: Rectangle {
                                            implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                        }
                                        contentItem: Text {
                                            text: parent.displayText
                                            color: "#FFFFFF"
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 10
                                            rightPadding: 30
                                        }
                                        delegate: ItemDelegate {
                                            width: comboCourse.width; height: 40
                                            contentItem: Text {
                                                text: modelData
                                                color: "#FFFFFF"
                                                font.pixelSize: 13
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                        }
                                        popup: Popup {
                                            y: comboCourse.height - 1; width: comboCourse.width; padding: 1
                                            height: Math.min(contentItem.implicitHeight + 2, 250)
                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: comboCourse.popup.visible ? comboCourse.delegateModel : null
                                                currentIndex: comboCourse.highlightedIndex
                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }
                                            background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    spacing: 5
                                    Label { text: "Поток"; color: "#8B949E"; font.pixelSize: 13 }
                                    ComboBox {
                                        id: comboStream
                                        Layout.fillWidth: true
                                        model: ["Загрузка..."]

                                        background: Rectangle {
                                            implicitHeight: 40; color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6
                                        }
                                        contentItem: Text {
                                            text: parent.displayText
                                            color: "#FFFFFF"
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 10
                                            rightPadding: 30
                                        }
                                        delegate: ItemDelegate {
                                            width: comboStream.width; height: 40
                                            contentItem: Text {
                                                text: modelData
                                                color: "#FFFFFF"
                                                font.pixelSize: 13
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            background: Rectangle { color: parent.highlighted ? "#2D333B" : "transparent" }
                                        }
                                        popup: Popup {
                                            y: comboStream.height - 1; width: comboStream.width; padding: 1
                                            height: Math.min(contentItem.implicitHeight + 2, 250)
                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: comboStream.popup.visible ? comboStream.delegateModel : null
                                                currentIndex: comboStream.highlightedIndex
                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }
                                            background: Rectangle { color: "#1C2128"; border.color: "#373E47"; border.width: 1; radius: 6 }
                                        }
                                    }
                                }
                            }

                            Button {
                                text: AuthManager.isScheduleLoading ? "Получение данных..." : "Загрузить расписание"
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
                                    let f = comboFac.currentText.toString().trim();
                                    let s = comboSpec.currentText.toString().trim();
                                    let c = comboCourse.currentText.toString().trim();
                                    let st = comboStream.currentText.toString().trim();

                                    if (f.indexOf("Выберите") !== -1 || s.indexOf("Выберите") !== -1 || c.indexOf("Выберите") !== -1 || st.indexOf("Выберите") !== -1 || f.indexOf("Загрузка") !== -1) {
                                        dashboardPage.currentPdfUrl = "";
                                        dashboardPage.scheduleErrorMsg = "Пожалуйста, выберите все параметры";
                                        dashboardPage.hasScheduleError = true;
                                        return;
                                    }

                                    let foundUrl = "";
                                    for (let i = 0; i < dashboardPage.allSchedules.length; i++) {
                                        let item = dashboardPage.allSchedules[i];
                                        if (item.faculty.toString().trim() === f &&
                                            item.speciality.toString().trim() === s &&
                                            item.course.toString().trim() === c &&
                                            item.stream.toString().trim() === st) {
                                            foundUrl = item.url;
                                            break;
                                        }
                                    }

                                    if (foundUrl !== "") {
                                        setFoundPdfUrl(foundUrl);
                                    } else {
                                        dashboardPage.currentPdfUrl = "";
                                        dashboardPage.scheduleErrorMsg = "Расписание для выбранных параметров не найдено";
                                        dashboardPage.hasScheduleError = true;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumHeight: dashboardPage.currentPdfUrl === "" ? 200 : 250
                        color: dashboardPage.currentPdfUrl === "" ? "transparent" : "#22272E"
                        radius: 12
                        border.color: "#373E47"
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.max(parent.width - 40, 100)
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
                                text: dashboardPage.hasScheduleError ? dashboardPage.scheduleErrorMsg : "Расписание пока не загружено"
                                color: dashboardPage.hasScheduleError ? "#ef4444" : "#8B949E"
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 4
                            active: dashboardPage.currentPdfUrl !== ""
                            sourceComponent: Component {
                                Item {
                                    anchors.fill: parent

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 20

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: 60; height: 60; radius: 30
                                            color: "#CC1C2128"
                                            border.color: "#2ea043"
                                            border.width: 2

                                            Label {
                                                anchors.centerIn: parent
                                                text: "📄"
                                                font.pixelSize: 30
                                            }
                                        }

                                        Label {
                                            text: "Успешно загружено!"
                                            color: "#2ea043"
                                            font.pixelSize: 18
                                            font.bold: true
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Button {
                                            text: "Открыть на весь экран"
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.topMargin: 10
                                            Layout.preferredWidth: 240
                                            Layout.preferredHeight: 50

                                            background: Rectangle {
                                                color: parent.pressed ? "#1557B0" : "#1F6FEB"
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
                                                if (dashboardPage.currentPdfUrl !== "") {
                                                    Qt.openUrlExternally(dashboardPage.currentPdfUrl);
                                                }
                                            }
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