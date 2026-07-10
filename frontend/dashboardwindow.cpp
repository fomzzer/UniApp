#include "dashboardwindow.h"
#include "ui_dashboardwindow.h"
#include <QHeaderView>

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
}

DashboardWindow::~DashboardWindow()
{
    delete ui;
}
