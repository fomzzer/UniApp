#include "loginwindow.h"
#include "dashboardwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    LoginWindow *logWin = new LoginWindow();
    DashboardWindow *dashWin = new DashboardWindow();

    QObject::connect(logWin, &LoginWindow::loginSuccessful, [=](const QString &userName, const QStringList &userInfo) {
        dashWin->setUserName(userName);
        dashWin->setUserInfo(userInfo);
        logWin->hide();
        dashWin->show();
        logWin->deleteLater();
    });

    logWin->show();

    return a.exec();
}
