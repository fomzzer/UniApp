#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonArray>
#include <QStringList>

class AuthManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit AuthManager(QObject *parent = nullptr);
    bool isLoading() const;

    Q_INVOKABLE void login(const QString &facultyNo, const QString &authCode);

signals:
    void isLoadingChanged();
    void loginSuccess(const QString &userName, const QJsonObject &userInfo, const QJsonArray &gradesInfo, const QString &dormStatus);
    void loginError(const QString &errorMessage);

private slots:
    void onServerResponse(QNetworkReply* reply);

private:
    QNetworkAccessManager *networkManager;
    bool m_isLoading;
    void setLoading(bool loading);
};

#endif // AUTHMANAGER_H