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

    ui->combo_degree->setPlaceholderText("Выберите ступень");
    ui->combo_faculty->setPlaceholderText("Выберите факультет");
    ui->combo_specialty->setPlaceholderText("Выберите специальность");
    ui->combo_course->setPlaceholderText("Выберите курс");
    ui->combo_stream->setPlaceholderText("Выберите поток");

    loadSchedulesJson();

    updateDegrees();
    updateFaculties();
    updateSpecialties();
    updateCoursesAndStreams();

    connect(ui->combo_degree, &QComboBox::currentTextChanged, [=]() {
        updateFaculties();
        updateSpecialties();
        updateCoursesAndStreams();
    });

    connect(ui->combo_faculty, &QComboBox::currentTextChanged, [=]() {
        updateSpecialties();
        updateCoursesAndStreams();
    });

    connect(ui->combo_specialty, &QComboBox::currentTextChanged, [=]() {
        updateCoursesAndStreams();
    });

    connect(ui->btn_open_schedule, &QPushButton::clicked, [=]() {
        QString selDegree = ui->combo_degree->currentText();
        QString selFaculty = ui->combo_faculty->currentText();
        QString selSpecialty = ui->combo_specialty->currentText();
        QString selCourse = ui->combo_course->currentText();
        QString selStream = ui->combo_stream->currentText();

        for (int i = 0; i < m_schedules.size(); ++i) {
            QJsonObject obj = m_schedules[i].toObject();
            if (obj["degree"].toString() == selDegree &&
                obj["faculty"].toString() == selFaculty &&
                obj["specialty"].toString() == selSpecialty &&
                obj["course"].toString() == selCourse &&
                obj["stream"].toString() == selStream)
            {
                QDesktopServices::openUrl(QUrl(obj["url"].toString()));
                return;
            }
        }
    });
}

DashboardWindow::~DashboardWindow()
{
    delete ui;
}

void DashboardWindow::loadSchedulesJson() {
    QFile file("schedules.json");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        file.setFileName("../frontend/schedules.json");
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    m_schedules = doc.array();
}

void DashboardWindow::updateDegrees() {
    ui->combo_degree->clear();
    QSet<QString> uniqueDegrees;
    for (int i = 0; i < m_schedules.size(); ++i) {
        uniqueDegrees.insert(m_schedules[i].toObject()["degree"].toString());
    }
    ui->combo_degree->addItems(uniqueDegrees.values());
    ui->combo_degree->setCurrentIndex(-1);
}

void DashboardWindow::updateFaculties() {
    ui->combo_faculty->clear();
    QSet<QString> uniqueFaculties;

    for (int i = 0; i < m_schedules.size(); ++i) {
        QJsonObject obj = m_schedules[i].toObject();
        uniqueFaculties.insert(obj["faculty"].toString());
    }

    ui->combo_faculty->addItems(uniqueFaculties.values());
    ui->combo_faculty->setCurrentIndex(-1);
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
    ui->combo_specialty->addItems(uniqueSpecialties.values());
    ui->combo_specialty->setCurrentIndex(-1);
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
    ui->combo_course->addItems(uniqueCourses.values());
    ui->combo_stream->addItems(uniqueStreams.values());
    ui->combo_course->setCurrentIndex(-1);
    ui->combo_stream->setCurrentIndex(-1);
}