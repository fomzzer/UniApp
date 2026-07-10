#ifndef LOGINWINDOW_H
#define LOGINWINDOW_H

#include <QMainWindow>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

QT_BEGIN_NAMESPACE
namespace Ui {
class LoginWindow;
}
QT_END_NAMESPACE

class LoginWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit LoginWindow(QWidget *parent = nullptr);
    ~LoginWindow() override;

private slots:
    void onLoginButtonClicked();
    void onServerResponse(QNetworkReply* reply);

private:
    Ui::LoginWindow *ui;
    QNetworkAccessManager *networkManager;
};
#endif // LOGINWINDOW_H
