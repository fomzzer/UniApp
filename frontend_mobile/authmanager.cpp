#include "authmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QUrl>
#include <QFile>
#include <QStandardPaths>

AuthManager::AuthManager(QObject *parent)
    : QObject(parent), m_isLoading(false), m_isScheduleLoading(false)
{
    networkManager = new QNetworkAccessManager(this);
    connect(networkManager, &QNetworkAccessManager::finished, this, &AuthManager::onServerResponse);

    scheduleNetworkManager = new QNetworkAccessManager(this);
    connect(scheduleNetworkManager, &QNetworkAccessManager::finished, this, &AuthManager::onScheduleResponse);

    pdfManager = new QNetworkAccessManager(this);
    connect(pdfManager, &QNetworkAccessManager::finished, this, &AuthManager::onPdfResponse);
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

void AuthManager::fetchAllSchedules() {
    setScheduleLoading(true);
    QUrl url("http://20.215.255.122:8000/api/schedules");
    QNetworkRequest request(url);
    scheduleNetworkManager->get(request);
}

void AuthManager::onScheduleResponse(QNetworkReply* reply) {
    setScheduleLoading(false);

    if (reply->error() != QNetworkReply::NoError) {
        emit scheduleError("Ошибка сети: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);

    if (doc.isArray()) {
        emit allSchedulesReceived(doc.array());
    } else {
        emit scheduleError("Сервер вернул некорректный формат расписания");
    }
    reply->deleteLater();
}

void AuthManager::downloadPdf(const QString &urlStr) {
    setScheduleLoading(true);
    QUrl url(urlStr);
    QNetworkRequest request(url);

    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    pdfManager->get(request);
}

void AuthManager::onPdfResponse(QNetworkReply* reply) {
    setScheduleLoading(false);

    if (reply->error() != QNetworkReply::NoError) {
        emit scheduleError("Ошибка загрузки файла: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/current_schedule.pdf";
    QFile file(tempPath);

    if (file.open(QIODevice::WriteOnly)) {
        file.write(reply->readAll());
        file.close();

        QString safeUrl = QUrl::fromLocalFile(tempPath).toString();
        emit pdfDownloaded(safeUrl);
    } else {
        emit scheduleError("Не удалось сохранить PDF на устройство");
    }

    reply->deleteLater();
}