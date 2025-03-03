# Admission Webhook Ingress-Nginx с использованием Cert-Manager

## Обзор

Этот документ объясняет, как сертификаты admission webhook для ingress-nginx управляются с помощью cert-manager вместо статических сертификатов.

## Конфигурация

Сертификаты admission webhook для ingress-nginx теперь динамически управляются с помощью cert-manager. Этот подход имеет несколько преимуществ:

1. Автоматическая ротация сертификатов до истечения срока действия
2. Централизованное управление сертификатами
3. Согласованный процесс выдачи сертификатов
4. Отсутствие необходимости в ручном обновлении статических сертификатов

## Детали реализации

### Ресурс Certificate

В пространстве имен `ingress-nginx` создан ресурс Certificate, который определяет, как cert-manager должен генерировать и управлять сертификатами admission webhook:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ingress-nginx-admission
  namespace: ingress-nginx
spec:
  secretName: ingress-nginx-admission
  duration: 8760h # 1 год
  renewBefore: 720h # 30 дней
  subject:
    organizations:
      - ingress-nginx
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  dnsNames:
    - ingress-nginx-controller-admission.ingress-nginx.svc
    - ingress-nginx-controller-admission.ingress-nginx.svc.cluster.local
  issuerRef:
    name: prod-local-issuer
    kind: ClusterIssuer
    group: cert-manager.io
```

### Конфигурация Ingress-Nginx

Helm-чарт ingress-nginx настроен на использование cert-manager для управления сертификатами:

```yaml
admissionWebhooks:
  enabled: true
  certManager:
    enabled: true
    rootCert:
      issuerRef:
        name: prod-local-issuer
        kind: ClusterIssuer
    admissionCert:
      issuerRef:
        name: prod-local-issuer
        kind: ClusterIssuer
```

## Обслуживание

Для обновления сертификатов не требуется ручного вмешательства. Cert-manager автоматически обновит сертификаты до истечения срока их действия.

Если вам необходимо изменить конфигурацию сертификата, вы можете обновить ресурс Certificate или файл values.yaml для ingress-nginx.