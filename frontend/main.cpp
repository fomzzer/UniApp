#include "loginwindow.h"
#include "dashboardwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    LoginWindow *logWin = new LoginWindow();
    DashboardWindow *dashWin = new DashboardWindow();

    QObject::connect(logWin, &LoginWindow::loginSuccessful, [=]() {
        logWin->hide();
        dashWin->show();
        logWin->deleteLater();
    });

    logWin->show();

    return a.exec();
}
