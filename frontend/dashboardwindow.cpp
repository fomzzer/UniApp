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

#include <QDebug>

DashboardWindow::DashboardWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DashboardWindow)
{
    ui->setupUi(this);

    ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
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

    connect(ui->btn_update_data, &QPushButton::clicked, this, &DashboardWindow::fetchSchedules);
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
    ui->lbl_facultyno->setText(ui->lbl_facultyno->text().append(" " + info[0]));
    ui->lbl_faculty->setText(ui->lbl_faculty->text().append(" " + info[1]));
    ui->lbl_speciality->setText(ui->lbl_speciality->text().append(" " + info[2]));
    ui->lbl_typestyding->setText(ui->lbl_typestyding->text().append(" " + info[3]));
    ui->lbl_group->setText(ui->lbl_group->text().append(" " + info[4]));
    ui->lbl_stream->setText(ui->lbl_stream->text().append(" " + info[5]));

    scheduleInfo.clear();
    scheduleInfo.append(getAcronym(info[1]));
    scheduleInfo.append(getAcronym(info[2]));
    scheduleInfo.append(info[4]);
    scheduleInfo.append(info[5]);

    if (!schedules.isEmpty()) {
        setDefaultSchedule(scheduleInfo);
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