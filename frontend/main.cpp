#include "loginwindow.h"
#include "dashboardwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QCoreApplication::setOrganizationName("fomzzer");
    QCoreApplication::setApplicationName("UniApp");

    LoginWindow *logWin = new LoginWindow();
    DashboardWindow *dashWin = new DashboardWindow();

    QObject::connect(logWin, &LoginWindow::loginSuccessful, [=](const QString &userName, const QStringList &userInfo, const QJsonArray &gradesInfo) {
        dashWin->clearDashboardWindow();
        dashWin->setUserName(userName);
        dashWin->setUserInfo(userInfo);
        dashWin->setUserGrades(gradesInfo);
        logWin->hide();
        dashWin->show();
    });

    QObject::connect(dashWin, &DashboardWindow::logoutRequested, [=]() {
        logWin->clearLoginWindow();
        dashWin->hide();
        logWin->show();
    });

    logWin->show();

    return a.exec();
}
