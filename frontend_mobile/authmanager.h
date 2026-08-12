#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>

class AuthManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(bool isScheduleLoading READ isScheduleLoading NOTIFY isScheduleLoadingChanged)

public:
    explicit AuthManager(QObject *parent = nullptr);
    bool isLoading() const;
    bool isScheduleLoading() const;

    Q_INVOKABLE void login(const QString &facultyNo, const QString &authCode);
    Q_INVOKABLE void fetchAllSchedules();

    Q_INVOKABLE void downloadPdf(const QString &urlStr);

signals:
    void isLoadingChanged();
    void isScheduleLoadingChanged();

    void loginSuccess(const QString &userName, const QJsonObject &userInfo, const QJsonArray &gradesInfo, const QString &dormStatus);
    void loginError(const QString &errorMessage);

    void allSchedulesReceived(const QJsonArray &schedules);
    void scheduleError(const QString &errorMessage);

    void pdfDownloaded(const QString &localPath);

private slots:
    void onServerResponse(QNetworkReply* reply);
    void onScheduleResponse(QNetworkReply* reply);
    void onPdfResponse(QNetworkReply* reply);

private:
    QNetworkAccessManager *networkManager;
    QNetworkAccessManager *scheduleNetworkManager;
    QNetworkAccessManager *pdfManager;

    bool m_isLoading;
    bool m_isScheduleLoading;

    void setLoading(bool loading);
    void setScheduleLoading(bool loading);
};

#endif // AUTHMANAGER_H