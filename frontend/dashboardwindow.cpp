#include "dashboardwindow.h"
#include "ui_dashboardwindow.h"
#include <QHeaderView>
#include <QDesktopServices>
#include <QUrl>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSet>
#include <QProcess>
#include <QCoreApplication>

DashboardWindow::DashboardWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DashboardWindow)
{
    ui->setupUi(this);

    ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
    ui->stackedWidget->setCurrentIndex(0);

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

    loadSchedulesJson();

    updateFaculties();
    updateSpecialties();
    updateCoursesAndStreams();

    connect(ui->combo_faculty, &QComboBox::currentTextChanged, [=]() {
        updateSpecialties();
        updateCoursesAndStreams();
    });

    connect(ui->combo_specialty, &QComboBox::currentTextChanged, [=]() {
        updateCoursesAndStreams();
    });

    connect(ui->btn_open_schedule, &QPushButton::clicked, [=]() {
        QString selFaculty = ui->combo_faculty->currentText();
        QString selSpecialty = ui->combo_specialty->currentText();
        QString selCourse = ui->combo_course->currentText();
        QString selStream = ui->combo_stream->currentText();

        for (int i = 0; i < m_schedules.size(); ++i) {
            QJsonObject obj = m_schedules[i].toObject();
            if (obj["faculty"].toString() == selFaculty &&
                obj["specialty"].toString() == selSpecialty &&
                obj["course"].toString() == selCourse &&
                obj["stream"].toString() == selStream)
            {
                QDesktopServices::openUrl(QUrl(obj["url"].toString()));
                return;
            }
        }
    });

    connect(ui->btn_update_data, &QPushButton::clicked, this, &DashboardWindow::startPythonScrapper);
}

DashboardWindow::~DashboardWindow()
{
    delete ui;
}

void DashboardWindow::loadSchedulesJson() {
    QFile file("schedules.json");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        file.setFileName("../backend/schedules.json");
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    m_schedules = doc.array();
}

void DashboardWindow::updateFaculties() {
    ui->combo_faculty->clear();
    QSet<QString> uniqueFaculties;

    for (int i = 0; i < m_schedules.size(); ++i) {
        QJsonObject obj = m_schedules[i].toObject();
        uniqueFaculties.insert(obj["faculty"].toString());
    }

    ui->combo_faculty->addItem("Выберите факультет");
    ui->combo_faculty->addItems(uniqueFaculties.values());
    ui->combo_faculty->setCurrentIndex(0);
}

void DashboardWindow::updateSpecialties() {
    ui->combo_specialty->clear();
    QString currentFaculty = ui->combo_faculty->currentText();
    QSet<QString> uniqueSpecialties;

    for (int i = 0; i < m_schedules.size(); ++i) {
        QJsonObject obj = m_schedules[i].toObject();
        if (obj["faculty"].toString() == currentFaculty) {
            uniqueSpecialties.insert(obj["specialty"].toString());
        }
    }

    ui->combo_specialty->addItem("Выберите специальность");
    ui->combo_specialty->addItems(uniqueSpecialties.values());
    ui->combo_specialty->setCurrentIndex(0);
}

void DashboardWindow::updateCoursesAndStreams() {
    ui->combo_course->clear();
    ui->combo_stream->clear();

    QString currentFaculty = ui->combo_faculty->currentText();
    QString currentSpecialty = ui->combo_specialty->currentText();

    QSet<QString> uniqueCourses;
    QSet<QString> uniqueStreams;

    for (int i = 0; i < m_schedules.size(); ++i) {
        QJsonObject obj = m_schedules[i].toObject();
        if (obj["faculty"].toString() == currentFaculty && obj["specialty"].toString() == currentSpecialty) {
            uniqueCourses.insert(obj["course"].toString());
            uniqueStreams.insert(obj["stream"].toString());
        }
    }

    ui->combo_course->addItem("Выберите курс");
    ui->combo_stream->addItem("Выберите поток");
    ui->combo_course->addItems(uniqueCourses.values());
    ui->combo_stream->addItems(uniqueStreams.values());
    ui->combo_course->setCurrentIndex(0);
    ui->combo_stream->setCurrentIndex(0);
}

void DashboardWindow::startPythonScrapper() {
    ui->btn_update_data->setEnabled(false);
    ui->btn_update_data->setText("Скачивание данных...");

    QProcess *process = new QProcess(this);

    connect(process, &QProcess::finished, this, [this, process](int exitCode) {
        ui->btn_update_data->setEnabled(true);
        ui->btn_update_data->setText("Обновить данные");

        if (exitCode == 0) {
            loadSchedulesJson();
        }

        process->deleteLater();
    });

    QString scriptPath = QCoreApplication::applicationDirPath() + "/scraper.py";
    process->start("python", QStringList() << "-u" << scriptPath);
}

void DashboardWindow::setUserName(const QString &name) {
    ui->lbl_name->setText(name);
}

void DashboardWindow::setUserInfo(const QStringList &info) {
    ui->lbl_facultyno->setText(info[0]);
    ui->lbl_faculty->setText(info[1]);
    ui->lbl_speciality->setText(info[2]);
    ui->lbl_typestyding->setText(info[3]);
    ui->lbl_group->setText(info[4]);
    ui->lbl_stream->setText(info[5]);
}