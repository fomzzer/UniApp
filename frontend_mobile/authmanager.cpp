#include "authmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QUrl>

AuthManager::AuthManager(QObject *parent)
    : QObject(parent), m_isLoading(false), m_isScheduleLoading(false)
{
    networkManager = new QNetworkAccessManager(this);
    connect(networkManager, &QNetworkAccessManager::finished, this, &AuthManager::onServerResponse);

    scheduleNetworkManager = new QNetworkAccessManager(this);
    connect(scheduleNetworkManager, &QNetworkAccessManager::finished, this, &AuthManager::onScheduleResponse);
}

bool AuthManager::isLoading() const { return m_isLoading; }
bool AuthManager::isScheduleLoading() const { return m_isScheduleLoading; }

void AuthManager::setLoading(bool loading) {
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void AuthManager::setScheduleLoading(bool loading) {
    if (m_isScheduleLoading != loading) {
        m_isScheduleLoading = loading;
        emit isScheduleLoadingChanged();
    }
}

void AuthManager::login(const QString &facultyNo, const QString &authCode) {
    if (facultyNo.isEmpty() || authCode.isEmpty()) {
        emit loginError("Поля не заполнены");
        return;
    }

    setLoading(true);

    QUrl url("http://20.215.255.122:8000/api/login");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["faculty_no"] = facultyNo;
    json["auth_code"] = authCode;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    networkManager->post(request, data);
}

void AuthManager::onServerResponse(QNetworkReply* reply) {
    setLoading(false);

    if (reply->error() != QNetworkReply::NoError) {
        emit loginError("Не удалось связаться с сервером: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument replyDoc = QJsonDocument::fromJson(responseData);
    QJsonObject replyJson = replyDoc.object();

    if (replyJson.contains("status") && replyJson["status"].toString() == "success") {
        QString userName = replyJson["name"].toString();
        QJsonObject userInfo = replyJson["info"].toObject();
        QJsonArray gradesInfo = replyJson["grades"].toArray();

        QJsonObject dormObj = replyJson["dormitory"].toObject();
        QString dormStatus = dormObj["status"].toString();

        emit loginSuccess(userName, userInfo, gradesInfo, dormStatus);
    }
    else {
        emit loginError("Ошибка получения данных. Проверьте учетные данные или повторите попытку.");
    }

    reply->deleteLater();
}

void AuthManager::fetchSchedule(const QString &faculty, const QString &specialty, const QString &course, const QString &group) {
    setScheduleLoading(true);

    QUrl url("http://20.215.255.122:8000/api/schedule");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["faculty"] = faculty;
    json["specialty"] = specialty;
    json["course"] = course;
    json["group"] = group;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    scheduleNetworkManager->post(request, data);
}

void AuthManager::onScheduleResponse(QNetworkReply* reply) {
    setScheduleLoading(false);

    if (reply->error() != QNetworkReply::NoError) {
        emit scheduleError("Ошибка сети: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument replyDoc = QJsonDocument::fromJson(responseData);
    QJsonObject replyJson = replyDoc.object();

    if (replyJson.contains("status") && replyJson["status"].toString() == "success") {
        QString pdfUrl = replyJson["url"].toString();
        emit scheduleUrlReceived(pdfUrl);
    } else {
        emit scheduleError("Расписание для выбранных параметров не найдено");
    }

    reply->deleteLater();
}