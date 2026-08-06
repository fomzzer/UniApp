#include "loginwindow.h"
#include "dashboardwindow.h"
#include "ui_loginwindow.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QStringList>
#include <QRegularExpressionValidator>
#include <QKeyEvent>
#include <QSettings>

LoginWindow::LoginWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::LoginWindow)
{
    ui->setupUi(this);

    QSettings settings;

    if (settings.contains("login") && settings.contains("password")) {
        ui->lineEdit->setText(settings.value("login").toString());

        QByteArray savedPassword = settings.value("password").toByteArray();
        ui->lineEdit_2->setText(QString::fromUtf8(QByteArray::fromBase64(savedPassword)));

        ui->checkBox_remember->setChecked(true);
    }

    ui->label->setFocus();

    networkManager = new QNetworkAccessManager(this);
    connect(networkManager, &QNetworkAccessManager::finished, this, &LoginWindow::onServerResponse);

    ui->lineEdit->setValidator(new QRegularExpressionValidator(QRegularExpression("^\\d*$"), this));
    ui->lineEdit_2->setValidator(new QRegularExpressionValidator(QRegularExpression("^\\d*$"), this));

    connect(ui->lineEdit, &QLineEdit::returnPressed, this, &LoginWindow::onLoginButtonClicked);
    connect(ui->lineEdit_2, &QLineEdit::returnPressed, this, &LoginWindow::onLoginButtonClicked);

    ui->lineEdit->installEventFilter(this);
    ui->lineEdit_2->installEventFilter(this);
}

LoginWindow::~LoginWindow()
{
    delete ui;
}

void LoginWindow::onLoginButtonClicked() {

    QString login = ui->lineEdit->text().trimmed();
    QString password = ui->lineEdit_2->text().trimmed();

    if (login.isEmpty() && password.isEmpty()) {
        ui->pushButton->setText("Поля не заполнены");
        return;
    }

    if (login.isEmpty()) {
        ui->pushButton->setText("Поле с факультетным номером не заполнено");
        return;
    }

    if (password.isEmpty()) {
        ui->pushButton->setText("Поле с 2FA/ЕГН/ЛНЧ не заполнено");
        return;
    }

    ui->pushButton->setText("Войти");

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

    if (replyJson.contains("status") && replyJson["status"].toString() == "success" && replyJson.contains("grades") && replyJson.contains("dormitory")) {
        QJsonArray gradesInfo = replyJson["grades"].toArray();

        QJsonObject dormObj = replyJson["dormitory"].toObject();
        QString dormStatus = dormObj["status"].toString();

        ui->pushButton->setText("Войти");
        QString userName = replyJson["name"].toString();
        QJsonObject userInfoObject = replyJson["info"].toObject();
        QString facultyNo = userInfoObject["Фак. номер"].toString();
        QString faculty = userInfoObject["Факултет"].toString();
        QString speciality = userInfoObject["Специалност"].toString();
        QString typeStydying = userInfoObject["Вид обучение"].toString();
        QString group = userInfoObject["Група"].toString();
        QString stream = userInfoObject["Поток"].toString();
        QString semester = userInfoObject["Записан семестър"].toString();
        QString course = QString::number((semester.toInt() + 1) / 2);
        QString currentFactCourse = QString::number((semester.toInt() - 1) / 2);
        QString degree = userInfoObject["ОКС"].toString();
        QString tuEmail = userInfoObject["Имейл в ТУ - София"].toString();
        QStringList userInfo = {facultyNo, faculty, speciality, typeStydying, group, stream, semester, course, currentFactCourse, degree, tuEmail};

        QSettings settings;

        if (ui->checkBox_remember->isChecked()) {
            settings.setValue("login", ui->lineEdit->text().trimmed());

            QByteArray passwordBytes = ui->lineEdit_2->text().trimmed().toUtf8();
            settings.setValue("password", passwordBytes.toBase64());
        }
        else {
            settings.remove("login");
            settings.remove("password");
        }

        emit loginSuccessful(userName, userInfo, gradesInfo, dormStatus);
    }
    else {
        ui->pushButton->setText("Войти");
        QMessageBox::critical(this, "Ошибка", "Ошибка получения данных. Возможно, введен неверный факультетный номер или пароль. Так же, возможно ИИ неверно распознал каптчу. Попробуйте снова");
        return;
    }

    reply->deleteLater();
}

void LoginWindow::clearLoginWindow() {
    ui->lineEdit->clear();
    ui->lineEdit_2->clear();
    ui->checkBox_remember->setChecked(false);
}

bool LoginWindow::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::KeyPress) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);

        if (keyEvent->key() == Qt::Key_Down) {
            if (watched == ui->lineEdit) {
                ui->lineEdit_2->setFocus();
                return true;
            }
        }
        else if (keyEvent->key() == Qt::Key_Up) {
            if (watched == ui->lineEdit_2) {
                ui->lineEdit->setFocus();
                return true;
            }
        }
    }

    return QMainWindow::eventFilter(watched, event);
}