# Руководство по настройке SSL-сертификата

Этот документ содержит инструкции по настройке SSL-сертификата для вашего домена. Руководство охватывает процесс от покупки сертификата до его настройки на вашем сервере.

## Содержание

- [Введение](#введение)
- [Покупка SSL-сертификата](#покупка-ssl-сертификата)
- [Генерация CSR](#генерация-csr)
- [Подтверждение владения доменом](#подтверждение-владения-доменом)
- [Загрузка сертификата](#загрузка-сертификата)
- [Установка сертификата](#установка-сертификата)
  - [Настройка Nginx](#настройка-nginx)
  - [Настройка Apache](#настройка-apache)
  - [Настройка Kubernetes](#настройка-kubernetes)
- [Тестирование SSL-конфигурации](#тестирование-ssl-конфигурации)
- [Устранение неполадок](#устранение-неполадок)

## Введение

SSL (Secure Sockets Layer) сертификаты — это цифровые сертификаты, которые подтверждают подлинность веб-сайта и обеспечивают шифрованное соединение. Эти сертификаты необходимы для защиты конфиденциальной информации, передаваемой через ваш веб-сайт, такой как учетные данные для входа, личная информация и платежные данные.

Это руководство проведет вас через процесс настройки SSL-сертификата для домена, приобретенного через регистратора доменов (используя reg.ru в качестве примера).

## Покупка SSL-сертификата

1. Войдите в аккаунт вашего регистратора доменов (например, reg.ru)
2. Перейдите в раздел SSL-сертификатов
3. Выберите подходящий тип сертификата:
   - **Проверка домена (DV)**: Базовый уровень проверки, подтверждает только владение доменом
   - **Проверка организации (OV)**: Средний уровень, проверяет информацию об организации
   - **Расширенная проверка (EV)**: Высший уровень, требует тщательной проверки организации
4. Для стандартного домена (не wildcard) выберите сертификат для одного домена
5. Завершите процесс покупки

Пример использования reg.ru:

1. Войдите в свой аккаунт на reg.ru
2. Перейдите в раздел "SSL-сертификаты"
3. Выберите "Купить SSL-сертификат"
4. Выберите поставщика сертификатов (например, Comodo, Let's Encrypt и т.д.)
5. Выберите сертификат для одного домена для вашего домена (например, example.ru)
6. Завершите покупку

## Генерация CSR

Запрос на подпись сертификата (CSR) необходим для получения SSL-сертификата. CSR содержит информацию о вашем домене и организации.

### Использование OpenSSL

```bash
# Генерация приватного ключа
openssl genrsa -out example.ru.key 2048

# Генерация CSR с использованием приватного ключа
openssl req -new -key example.ru.key -out example.ru.csr
```

При запросе введите следующую информацию:
- **Common Name**: Имя вашего домена (например, example.ru)
- **Organization**: Название вашей компании
- **Organizational Unit**: Отдел (например, IT)
- **City/Locality**: Ваш город
- **State/Province**: Ваш регион/область
- **Country**: Код вашей страны (например, RU для России)
- **Email Address**: Ваш адрес электронной почты

### Использование онлайн-генераторов CSR

Многие регистраторы доменов предоставляют онлайн-генераторы CSR. Например, на reg.ru:

1. Перейдите на страницу управления SSL-сертификатами
2. Найдите инструмент для генерации CSR
3. Заполните необходимую информацию
4. Система сгенерирует как приватный ключ, так и CSR

**Важно**: Сохраните приватный ключ в надежном месте. Он потребуется позже для установки сертификата.

## Подтверждение владения доменом

После отправки вашего CSR вам необходимо подтвердить владение доменом. Распространенные методы проверки включают:

1. **Проверка по электронной почте**: Письмо с подтверждением отправляется на административный адрес электронной почты, связанный с доменом
2. **Проверка DNS**: Вы добавляете определенную TXT-запись в настройки DNS вашего домена
3. **HTTP-проверка**: Вы загружаете определенный файл на ваш веб-сервер

Пример использования проверки DNS:

1. Центр сертификации предоставляет значение TXT-записи
2. Войдите в панель управления DNS вашего домена
3. Добавьте новую TXT-запись:
   - Хост: Обычно `_acme-challenge` или как указано центром сертификации
   - Значение: Предоставленная строка проверки
4. Дождитесь распространения DNS (может занять до 24-48 часов)

## Загрузка сертификата

После завершения проверки вы можете загрузить файлы вашего SSL-сертификата:

1. Войдите в портал вашего поставщика сертификатов
2. Перейдите в раздел управления сертификатами
3. Загрузите следующие файлы:
   - Сертификат вашего домена (example.ru.crt)
   - Промежуточный сертификат(ы) (может быть объединен или отдельно)
   - Корневой сертификат (опционально, часто включен в операционные системы)

## Установка сертификата

### Настройка Nginx

1. Создайте директорию для ваших сертификатов:

```bash
sudo mkdir -p /etc/nginx/ssl/example.ru
```

2. Скопируйте файлы сертификатов в эту директорию:

```bash
sudo cp example.ru.crt /etc/nginx/ssl/example.ru/
sudo cp example.ru.key /etc/nginx/ssl/example.ru/
sudo cp intermediate.crt /etc/nginx/ssl/example.ru/
```

3. Настройте Nginx для использования сертификатов:

```nginx
server {
    listen 80;
    server_name example.ru www.example.ru;
    
    # Перенаправление HTTP на HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name example.ru www.example.ru;
    
    # Конфигурация SSL-сертификата
    ssl_certificate /etc/nginx/ssl/example.ru/example.ru.crt;
    ssl_certificate_key /etc/nginx/ssl/example.ru/example.ru.key;
    
    # Настройки SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # HSTS (опционально, но рекомендуется)
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Конфигурация вашего сайта
    root /var/www/example.ru;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

4. Проверьте конфигурацию Nginx:

```bash
sudo nginx -t
```

5. Если проверка успешна, перезагрузите Nginx:

```bash
sudo systemctl reload nginx
```

### Настройка Apache

1. Создайте директорию для ваших сертификатов:

```bash
sudo mkdir -p /etc/apache2/ssl/example.ru
```

2. Скопируйте файлы сертификатов в эту директорию:

```bash
sudo cp example.ru.crt /etc/apache2/ssl/example.ru/
sudo cp example.ru.key /etc/apache2/ssl/example.ru/
sudo cp intermediate.crt /etc/apache2/ssl/example.ru/
```

3. Включите модуль SSL:

```bash
sudo a2enmod ssl
```

4. Настройте Apache для использования сертификатов:

```apache
<VirtualHost *:80>
    ServerName example.ru
    ServerAlias www.example.ru
    
    # Перенаправление HTTP на HTTPS
    Redirect permanent / https://example.ru/
</VirtualHost>

<VirtualHost *:443>
    ServerName example.ru
    ServerAlias www.example.ru
    
    # Конфигурация SSL
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/example.ru/example.ru.crt
    SSLCertificateKeyFile /etc/apache2/ssl/example.ru/example.ru.key
    SSLCertificateChainFile /etc/apache2/ssl/example.ru/intermediate.crt
    
    # Настройки SSL
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLHonorCipherOrder on
    SSLCompression off
    
    # Конфигурация вашего сайта
    DocumentRoot /var/www/example.ru
    
    <Directory /var/www/example.ru>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

5. Проверьте конфигурацию Apache:

```bash
sudo apachectl configtest
```

6. Если проверка успешна, перезагрузите Apache:

```bash
sudo systemctl reload apache2
```

### Настройка Kubernetes

Если вы используете Kubernetes, существует несколько способов настройки SSL-сертификатов для ваших приложений:

#### Метод 1: Прямое использование TLS-секретов

1. Создайте TLS-секрет Kubernetes с вашим сертификатом и приватным ключом:

```bash
kubectl create secret tls example-ru-tls \
  --cert=example.ru.crt \
  --key=example.ru.key \
  --namespace=your-namespace
```

2. Настройте ресурс Ingress для использования этого TLS-секрета:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: your-namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - example.ru
    - www.example.ru
    secretName: example-ru-tls
  rules:
  - host: example.ru
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

#### Метод 2: Использование cert-manager

[cert-manager](https://cert-manager.io/) — это дополнение Kubernetes, которое автоматизирует управление и выпуск TLS-сертификатов. Его можно использовать для управления сертификатами от различных издателей, включая Let's Encrypt, или для использования ваших собственных приобретенных сертификатов.

1. Установите cert-manager в ваш кластер:

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

2. Создайте TLS-секрет с вашим приобретенным сертификатом:

```bash
kubectl create secret tls example-ru-tls \
  --cert=example.ru.crt \
  --key=example.ru.key \
  --namespace=your-namespace
```

3. Создайте ресурс Certificate, который ссылается на ваш секрет:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-ru-cert
  namespace: your-namespace
spec:
  secretName: example-ru-tls
  duration: 8760h # 1 год
  renewBefore: 720h # 30 дней
  subject:
    organizations:
      - Ваша Организация
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  dnsNames:
  - example.ru
  - www.example.ru
  issuerRef:
    name: your-issuer
    kind: ClusterIssuer
    group: cert-manager.io
```

4. Настройте ваш Ingress для использования этого сертификата:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: your-namespace
  annotations:
    cert-manager.io/cluster-issuer: "your-issuer"
spec:
  tls:
  - hosts:
    - example.ru
    - www.example.ru
    secretName: example-ru-tls
  rules:
  - host: example.ru
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

#### Метод 3: Использование значений Helm для настройки TLS

Если вы развертываете приложения с использованием Helm-чартов, вы часто можете настроить TLS непосредственно в файле values:

```yaml
# values.yaml
tls:
  enabled: true
  certificate: |
    -----BEGIN CERTIFICATE-----
    MIIDazCCAlOgAwIBAgIUJlq+zz4... (содержимое вашего сертификата)
    -----END CERTIFICATE-----
  key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvgIBADANBgkqhkiG9w0BAQE... (содержимое вашего приватного ключа)
    -----END PRIVATE KEY-----

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: example.ru
      paths:
        - path: /
          pathType: Prefix
```

Затем разверните ваше приложение с помощью:

```bash
helm install example-app ./your-chart -f values.yaml
```

## Тестирование SSL-конфигурации

После установки вашего SSL-сертификата проверьте, что он работает правильно:

1. Посетите ваш веб-сайт, используя HTTPS (https://example.ru)
2. Проверьте наличие значка замка в адресной строке браузера
3. Используйте онлайн-инструменты для тестирования SSL:
   - [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)
   - [SSL Checker](https://www.sslshopper.com/ssl-checker.html)

Эти инструменты проанализируют вашу SSL-конфигурацию и предоставят рекомендации по улучшению.

## Устранение неполадок

### Распространенные проблемы

1. **Сертификат не доверяется**: Убедитесь, что вы правильно установили промежуточный сертификат.
2. **Несоответствие сертификата**: Проверьте, что Common Name (CN) в вашем сертификате соответствует вашему домену.
3. **Предупреждения о смешанном содержимом**: Проверьте наличие HTTP-ресурсов, загружаемых на HTTPS-страницах.
4. **Истечение срока действия сертификата**: SSL-сертификаты имеют срок действия. Настройте напоминания для их обновления.

### Конкретные сообщения об ошибках

- **ERR_SSL_PROTOCOL_ERROR**: Проверьте вашу SSL-конфигурацию, особенно протоколы и шифры.
- **SEC_ERROR_UNKNOWN_ISSUER**: Промежуточный сертификат отсутствует или неправильно настроен.
- **SSL_ERROR_BAD_CERT_DOMAIN**: Сертификат был выпущен для другого домена.

### Проверка информации о сертификате

```bash
# Просмотр деталей сертификата
openssl x509 -in example.ru.crt -text -noout

# Проверка срока действия сертификата
openssl x509 -in example.ru.crt -noout -dates

# Проверка цепочки сертификатов
openssl verify -CAfile intermediate.crt example.ru.crt
```

### Устранение неполадок, специфичных для Kubernetes

Если вы используете Kubernetes, вы можете устранить проблемы с SSL с помощью следующих команд:

```bash
# Проверка статуса ваших сертификатов
kubectl get certificates -n your-namespace

# Проверка событий сертификата
kubectl describe certificate example-ru-cert -n your-namespace

# Проверка TLS-секретов
kubectl get secrets -n your-namespace | grep tls

# Проверка конфигурации ingress
kubectl describe ingress example-ingress -n your-namespace
```

---

Это руководство предоставляет общий обзор настройки SSL-сертификата. Точные шаги могут различаться в зависимости от вашей конкретной среды и требований. Всегда обращайтесь к документации вашего поставщика сертификатов для получения конкретных инструкций.
