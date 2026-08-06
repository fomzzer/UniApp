#ifndef DASHBOARDWINDOW_H
#define DASHBOARDWINDOW_H

#include <QMainWindow>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

namespace Ui {
class DashboardWindow;
}

class DashboardWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit DashboardWindow(QWidget *parent = nullptr);
    ~DashboardWindow();

    void setUserName(const QString &name);
    void setUserInfo(const QStringList &info);
    void setUserGrades(const QJsonArray &gradesInfo);
    void clearDashboardWindow();

signals:
    void logoutRequested();

private:
    Ui::DashboardWindow *ui;
    QJsonArray schedules;
    QNetworkAccessManager *networkManager;
    QStringList scheduleInfo;

    void updateFaculties();
    void updateSpecialties();
    void updateCourses();
    void updateStreams();
    void fetchSchedules();
    void setDefaultSchedule(const QStringList &scheduleInfo);
    QString getAcronym(const QString fullWord);

private slots:
    void onSchedulesReply(QNetworkReply* reply);
};

#endif // DASHBOARDWINDOW_H