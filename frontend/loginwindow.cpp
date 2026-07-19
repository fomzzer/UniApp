#include "loginwindow.h"
#include "dashboardwindow.h"
#include "ui_loginwindow.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QStringList>

LoginWindow::LoginWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::LoginWindow)
{
    ui->setupUi(this);

    ui->label->setFocus();

    networkManager = new QNetworkAccessManager(this);
    connect(networkManager, &QNetworkAccessManager::finished, this, &LoginWindow::onServerResponse);
}

LoginWindow::~LoginWindow()
{
    delete ui;
}

void LoginWindow::onLoginButtonClicked() {

    if (ui->lineEdit->text().isEmpty() && ui->lineEdit_2->text().isEmpty()) {
        ui->pushButton->setText("Поля не заполнены");
        return;
    }

    if (ui->lineEdit->text().isEmpty()) {
        ui->pushButton->setText("Поле с факультетным номером не заполнено");
        return;
    }

    if (ui->lineEdit_2->text().isEmpty()) {
        ui->pushButton->setText("Поле с паролем не заполнено");
        return;
    }

    QUrl url("http://20.215.255.122:8000/api/login");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["faculty_no"] = ui->lineEdit->text();
    json["auth_code"] = ui->lineEdit_2->text();

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    networkManager->post(request, data);
    ui->pushButton->setText("Отправка данных...");

}

void LoginWindow::onServerResponse(QNetworkReply* reply) {

    ui->pushButton->setText("Связываемся с сервером...");

    if (reply->error() != QNetworkReply::NoError) {
        QMessageBox::critical(this, "Ошибка", "Не удалось связаться с сервером: " + reply->errorString());
        reply->deleteLater();
        ui->pushButton->setText("Войти");
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument replyDoc = QJsonDocument::fromJson(responseData);
    QJsonObject replyJson = replyDoc.object();

    ui->pushButton->setText("Получаем данные...");

    if (replyJson.contains("status") && replyJson["status"].toString() == "success") {
        ui->pushButton->setText("Войти");
        QString userName = replyJson["name"].toString();
        QJsonObject userInfoObject = replyJson["info"].toObject();
        QString facultyNo = userInfoObject["Фак. номер"].toString();
        QString faculty = userInfoObject["Факултет"].toString();
        QString speciality = userInfoObject["Специалност"].toString();
        QString typeStydying = userInfoObject["Вид обучение"].toString();
        QString group = userInfoObject["Група"].toString();
        QString stream = userInfoObject["Поток"].toString();
        QStringList userInfo = {facultyNo, faculty, speciality, typeStydying, group, stream};
        emit loginSuccessful(userName, userInfo);
    }
    else {
        ui->pushButton->setText("Войти");
        QMessageBox::critical(this, "Ошибка", "Ошибка получения данных. Возможно, введен неверный факультетный номер или пароль");
        return;
    }

    reply->deleteLater();
}