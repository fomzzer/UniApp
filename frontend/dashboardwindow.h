#ifndef DASHBOARDWINDOW_H
#define DASHBOARDWINDOW_H

#include <QMainWindow>
#include <QJsonArray>

namespace Ui {
class DashboardWindow;
}

class DashboardWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit DashboardWindow(QWidget *parent = nullptr);
    ~DashboardWindow();

private:
    Ui::DashboardWindow *ui;
    QJsonArray m_schedules;

    void loadSchedulesJson();
    void updateDegrees();
    void updateFaculties();
    void updateSpecialties();
    void updateCoursesAndStreams();

private slots:
    void startPythonScrapper();
};

#endif // DASHBOARDWINDOW_H