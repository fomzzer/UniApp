#include "loginwindow.h"
#include "ui_loginwindow.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>

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

    QUrl url("http://20.215.255.122:8000/api/login");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["facultyno"] = ui->lineEdit->text();
    json["pass"] = ui->lineEdit_2->text();

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
        QString student = replyJson["student_name"].toString();
        QMessageBox::information(this, "Успех", "Добро пожаловать, " + student);
    }

    reply->deleteLater();
}