#include "dashboardwindow.h"
#include "ui_dashboardwindow.h"
#include <QHeaderView>
#include <QDesktopServices>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSet>
#include <QMessageBox>
#include <QSettings>

DashboardWindow::DashboardWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DashboardWindow)
{
    ui->setupUi(this);

    ui->tableWidget->setEditTriggers(QAbstractItemView::NoEditTriggers);

    ui->tableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
    ui->tableWidget->setSelectionMode(QAbstractItemView::SingleSelection);

    ui->tableWidget->horizontalHeader()->setSectionResizeMode(0, QHeaderView::Stretch);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(1, QHeaderView::ResizeToContents);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(2, QHeaderView::ResizeToContents);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(3, QHeaderView::ResizeToContents);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(4, QHeaderView::ResizeToContents);

    ui->tableWidget->setWordWrap(true);
    ui->tableWidget->setTextElideMode(Qt::ElideNone);
    ui->tableWidget->verticalHeader()->setSectionResizeMode(QHeaderView::ResizeToContents);

    ui->tableWidget->verticalHeader()->setVisible(false);

    ui->stackedWidget->setCurrentIndex(0);

    networkManager = new QNetworkAccessManager(this);
    connect(networkManager, &QNetworkAccessManager::finished, this, &DashboardWindow::onSchedulesReply);

    connect(ui->btn_profile, &QPushButton::clicked, [=]() {
        ui->stackedWidget->setCurrentIndex(0);
    });

    connect(ui->btn_grades, &QPushButton::clicked, [=]() {
        ui->stackedWidget->setCurrentIndex(1);
    });

    connect(ui->btn_schedule, &QPushButton::clicked, [=]() {
        ui->stackedWidget->setCurrentIndex(2);
    });

    connect(ui->btn_dorm, &QPushButton::clicked, [=]() {
        ui->stackedWidget->setCurrentIndex(3);
    });

    connect(ui->btn_info, &QPushButton::clicked, [=]() {
        ui->stackedWidget->setCurrentIndex(4);
    });

    connect(ui->btn_logout, &QPushButton::clicked, this, [=]() {
        QSettings settings;
        settings.remove("login");
        settings.remove("password");

        emit logoutRequested();
    });

    fetchSchedules();

    updateFaculties();
    updateSpecialties();
    updateCourses();
    updateStreams();

    connect(ui->combo_faculty, &QComboBox::currentTextChanged, [=]() {
        updateSpecialties();
        updateCourses();
        updateStreams();
    });

    connect(ui->combo_speciality, &QComboBox::currentTextChanged, [=]() {
        updateCourses();
        updateStreams();
    });

    connect(ui->combo_course, &QComboBox::currentTextChanged, [=]() {
        updateStreams();
    });

    connect(ui->btn_open_schedule, &QPushButton::clicked, [=]() {
        QString selFaculty = ui->combo_faculty->currentText();
        QString selSpecialty = ui->combo_speciality->currentText();
        QString selCourse = ui->combo_course->currentText();
        QString selStream = ui->combo_stream->currentText();

        for (int i = 0; i < schedules.size(); ++i) {
            QJsonObject obj = schedules[i].toObject();
            if (obj["faculty"].toString() == selFaculty &&
                obj["speciality"].toString() == selSpecialty &&
                obj["course"].toString() == selCourse &&
                obj["stream"].toString() == selStream)
            {
                QDesktopServices::openUrl(QUrl(obj["url"].toString()));
                return;
            }
        }
    });

    connect(ui->btn_update_data, &QPushButton::clicked, this, [=](){
        ui->combo_faculty->setCurrentIndex(0);
        ui->combo_speciality->setCurrentIndex(0);
        ui->combo_course->setCurrentIndex(0);
        ui->combo_stream->setCurrentIndex(0);
        fetchSchedules();
    });
}

DashboardWindow::~DashboardWindow()
{
    delete ui;
}

void DashboardWindow::fetchSchedules() {
    ui->btn_update_data->setEnabled(false);
    ui->btn_update_data->setText("Загрузка данных...");

    QUrl url("http://20.215.255.122:8000/api/schedules");
    QNetworkRequest request(url);
    networkManager->get(request);
}

void DashboardWindow::onSchedulesReply(QNetworkReply* reply) {
    ui->btn_update_data->setEnabled(true);
    ui->btn_update_data->setText("Обновить данные");

    if (reply->error() != QNetworkReply::NoError) {
        QMessageBox::critical(this, "Ошибка", "Не удалось обновить расписание с сервера: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);

    if (doc.isArray()) {
        schedules = doc.array();

        updateFaculties();
        updateSpecialties();
        updateCourses();
        updateStreams();

        if (!scheduleInfo.isEmpty()) {
            setDefaultSchedule(scheduleInfo);
        }
    }
    else {
        QMessageBox::warning(this, "Предупреждение", "Сервер вернул некорректный формат данных.");
    }

    reply->deleteLater();
}

void DashboardWindow::updateFaculties() {
    ui->combo_faculty->clear();
    QSet<QString> uniqueFaculties;

    for (int i = 0; i < schedules.size(); ++i) {
        QJsonObject obj = schedules[i].toObject();
        uniqueFaculties.insert(obj["faculty"].toString());
    }

    ui->combo_faculty->addItem("Выберите факультет");
    ui->combo_faculty->addItems(uniqueFaculties.values());
    ui->combo_faculty->setCurrentIndex(0);
}

void DashboardWindow::updateSpecialties() {
    ui->combo_speciality->clear();
    QString currentFaculty = ui->combo_faculty->currentText();
    QSet<QString> uniqueSpecialties;

    for (int i = 0; i < schedules.size(); ++i) {
        QJsonObject obj = schedules[i].toObject();
        if (obj["faculty"].toString() == currentFaculty) {
            uniqueSpecialties.insert(obj["speciality"].toString());
        }
    }

    ui->combo_speciality->addItem("Выберите специальность");
    ui->combo_speciality->addItems(uniqueSpecialties.values());
    ui->combo_speciality->setCurrentIndex(0);
}

void DashboardWindow::updateCourses() {
    ui->combo_course->clear();

    QString currentFaculty = ui->combo_faculty->currentText();
    QString currentSpeciality = ui->combo_speciality->currentText();
    QSet<QString> uniqueCourses;

    for (int i = 0; i < schedules.size(); ++i) {
        QJsonObject obj = schedules[i].toObject();
        if (obj["faculty"].toString() == currentFaculty && obj["speciality"].toString() == currentSpeciality) {
            uniqueCourses.insert(obj["course"].toString());
        }
    }

    ui->combo_course->addItem("Выберите курс");
    ui->combo_course->addItems(uniqueCourses.values());
    ui->combo_course->setCurrentIndex(0);
}

void DashboardWindow::updateStreams() {
    ui->combo_stream->clear();

    QString currentFaculty = ui->combo_faculty->currentText();
    QString currentSpeciality = ui->combo_speciality->currentText();
    QString currentCourse = ui->combo_course->currentText();
    QSet<QString> uniqueStreams;

    for (int i = 0; i < schedules.size(); ++i) {
        QJsonObject obj = schedules[i].toObject();
        if (obj["faculty"].toString() == currentFaculty &&
            obj["speciality"].toString() == currentSpeciality &&
            obj["course"].toString() == currentCourse) {

            uniqueStreams.insert(obj["stream"].toString());
        }
    }

    ui->combo_stream->addItem("Выберите поток");
    ui->combo_stream->addItems(uniqueStreams.values());
    ui->combo_stream->setCurrentIndex(0);
}

void DashboardWindow::setDefaultSchedule(const QStringList &scheduleInfo) {
    if (scheduleInfo.size() < 4) return;

    ui->combo_faculty->blockSignals(true);
    ui->combo_speciality->blockSignals(true);
    ui->combo_course->blockSignals(true);
    ui->combo_stream->blockSignals(true);

    int facultyIndex = ui->combo_faculty->findText(scheduleInfo[0]);
    if (facultyIndex != -1) {
        ui->combo_faculty->setCurrentIndex(facultyIndex);
    }

    updateSpecialties();
    int specialityIndex = ui->combo_speciality->findText(scheduleInfo[1]);
    if (specialityIndex != -1) {
        ui->combo_speciality->setCurrentIndex(specialityIndex);
    }

    updateCourses();
    int courseIndex = ui->combo_course->findText(scheduleInfo[2]);
    if (courseIndex != -1) {
        ui->combo_course->setCurrentIndex(courseIndex);
    }

    updateStreams();
    int streamIndex = ui->combo_stream->findText(scheduleInfo[3]);
    if (streamIndex != -1) {
        ui->combo_stream->setCurrentIndex(streamIndex);
    }

    ui->combo_faculty->blockSignals(false);
    ui->combo_speciality->blockSignals(false);
    ui->combo_course->blockSignals(false);
    ui->combo_stream->blockSignals(false);
}

void DashboardWindow::setUserName(const QString &name) {
    ui->lbl_name->setText(name);
}

void DashboardWindow::setUserInfo(const QStringList &info) {
    ui->lbl_degree->setText(ui->lbl_degree->text().append(" " + info[9]));
    ui->lbl_facultyno->setText(ui->lbl_facultyno->text().append(" " + info[0]));
    ui->lbl_faculty->setText(ui->lbl_faculty->text().append(" " + info[1]));
    ui->lbl_speciality->setText(ui->lbl_speciality->text().append(" " + info[2]));
    ui->lbl_typestyding->setText(ui->lbl_typestyding->text().append(" " + info[3]));
    ui->lbl_group->setText(ui->lbl_group->text().append(" " + info[4]));
    ui->lbl_stream->setText(ui->lbl_stream->text().append(" " + info[5]));
    ui->lbl_semester->setText(ui->lbl_semester->text().append(" " + info[6]));
    ui->lbl_course->setText(ui->lbl_course->text().append(" " + info[7]));

    scheduleInfo.clear();
    scheduleInfo.append(getAcronym(info[1]));
    scheduleInfo.append(getAcronym(info[2]));
    scheduleInfo.append(info[8]);
    scheduleInfo.append(info[5]);

    if (!schedules.isEmpty()) {
        setDefaultSchedule(scheduleInfo);
    }
}

void DashboardWindow::setUserGrades(const QJsonArray &gradesInfo) {
    ui->tableWidget->setRowCount(0);

    double totalSum = 0.0;
    int gradeCount = 0;

    for (int i = 0; i < gradesInfo.size(); ++i) {
        QJsonObject gradesObj = gradesInfo[i].toObject();
        int row = ui->tableWidget->rowCount();
        ui->tableWidget->insertRow(row);

        if (gradesObj.contains("is_semester") && gradesObj["is_semester"].toBool()) {
            QTableWidgetItem *semItem = new QTableWidgetItem(gradesObj["title"].toString());
            semItem->setTextAlignment(Qt::AlignCenter);

            QFont font = semItem->font();
            font.setBold(true);
            semItem->setFont(font);

            semItem->setBackground(QBrush(QColor(0x2d333b)));
            semItem->setForeground(QBrush(QColor(0x58a6ff)));

            ui->tableWidget->setItem(row, 0, semItem);
            ui->tableWidget->setSpan(row, 0, 1, 5);
            continue;
        }

        QTableWidgetItem *subjectItem = new QTableWidgetItem(gradesObj["subject"].toString());
        QTableWidgetItem *typeItem = new QTableWidgetItem(gradesObj["type"].toString());
        QTableWidgetItem *regItem = new QTableWidgetItem(gradesObj["regular"].toString());
        QTableWidgetItem *retakeItem = new QTableWidgetItem(gradesObj["retake"].toString());

        QString finalGradeStr = gradesObj["final"].toString();
        QTableWidgetItem *finalGradeItem = new QTableWidgetItem(finalGradeStr);

        typeItem->setTextAlignment(Qt::AlignCenter);
        regItem->setTextAlignment(Qt::AlignCenter);
        retakeItem->setTextAlignment(Qt::AlignCenter);
        finalGradeItem->setTextAlignment(Qt::AlignCenter);

        QRegularExpression re("\\((\\d+)\\)");
        QRegularExpressionMatch match = re.match(finalGradeStr);
        if (match.hasMatch()) {
            int val = match.captured(1).toInt();
            if (val >= 2 && val <= 6) {
                totalSum += val;
                gradeCount++;
            }
        }

        if (finalGradeStr.contains("(2)")) {
            finalGradeItem->setForeground(QBrush(QColor(0xef4444)));
        } else if (finalGradeStr.contains("(3)")) {
            finalGradeItem->setForeground(QBrush(QColor(0xf97316)));
        } else if (finalGradeStr.contains("(4)")) {
            finalGradeItem->setForeground(QBrush(QColor(0xeab308)));
        } else if (finalGradeStr.contains("(5)")) {
            finalGradeItem->setForeground(QBrush(QColor(0x84cc16)));
        } else if (finalGradeStr.contains("(6)") || finalGradeStr.contains("Зачита се", Qt::CaseInsensitive)) {
            finalGradeItem->setForeground(QBrush(QColor(0x22c55e)));
        }

        ui->tableWidget->setItem(row, 0, subjectItem);
        ui->tableWidget->setItem(row, 1, typeItem);
        ui->tableWidget->setItem(row, 2, regItem);
        ui->tableWidget->setItem(row, 3, retakeItem);
        ui->tableWidget->setItem(row, 4, finalGradeItem);
    }

    if (gradeCount > 0) {
        double gpa = totalSum / gradeCount;

        int row = ui->tableWidget->rowCount();
        ui->tableWidget->insertRow(row);

        QTableWidgetItem *gpaTitleItem = new QTableWidgetItem("Общ среден успех (GPA):");
        gpaTitleItem->setTextAlignment(Qt::AlignRight | Qt::AlignVCenter);

        QFont font = gpaTitleItem->font();
        font.setBold(true);
        gpaTitleItem->setFont(font);

        QString gpaStr = QString::number(gpa, 'f', 2);
        QTableWidgetItem *gpaValItem = new QTableWidgetItem(gpaStr);
        gpaValItem->setTextAlignment(Qt::AlignCenter);
        gpaValItem->setFont(font);

        if (gpa < 3.0) {
            gpaValItem->setForeground(QBrush(QColor(0xef4444)));
        } else if (gpa < 4.0) {
            gpaValItem->setForeground(QBrush(QColor(0xf97316)));
        } else if (gpa < 5.0) {
            gpaValItem->setForeground(QBrush(QColor(0xeab308)));
        } else if (gpa < 6.0) {
            gpaValItem->setForeground(QBrush(QColor(0x84cc16)));
        } else {
            gpaValItem->setForeground(QBrush(QColor(0x22c55e)));
        }

        ui->tableWidget->setItem(row, 0, gpaTitleItem);
        ui->tableWidget->setSpan(row, 0, 1, 4);
        ui->tableWidget->setItem(row, 4, gpaValItem);
    }
}

QString DashboardWindow::getAcronym(const QString fullWord) {
    QStringList words = fullWord.split(' ', Qt::SkipEmptyParts);
    QString acronym = "";

    for (const QString &word : words) {
        if (word.toLower() == "и" || word.toLower() == "в" || word.toLower() == "с" || word.toLower() == "по") {
            continue;
        }

        if (!word.isEmpty()) {
            acronym += word.at(0).toUpper();
        }
    }

    return acronym;
}

void DashboardWindow::clearDashboardWindow() {
    ui->lbl_name->clear();
    ui->lbl_degree->setText("Степень:");
    ui->lbl_facultyno->setText("Факультетный номер:");
    ui->lbl_faculty->setText("Факультет:");
    ui->lbl_speciality->setText("Специальность:");
    ui->lbl_typestyding->setText("Вид обучения:");
    ui->lbl_group->setText("Группа:");
    ui->lbl_stream->setText("Поток:");
    ui->lbl_semester->setText("Семестр:");
    ui->lbl_course->setText("Курс:");
}