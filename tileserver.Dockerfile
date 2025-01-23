FROM ubuntu:22.04

RUN apt update && apt install -y \
    apache2 \
    mapserver-bin \
    libapache2-mod-fcgid

# Set up DOI root certificate
COPY DOIRootCA2.crt /usr/local/share/ca-certificates
RUN chmod 644 /usr/local/share/ca-certificates/DOIRootCA2.crt && \
    update-ca-certificates
# you probably don't need all of these, but they don't hurt
ENV PIP_CERT="/etc/ssl/certs/ca-certificates.crt" \
    SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
    CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt" \
    REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt" \
    AWS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

# Copy SSL certs
COPY statmagic.crt /etc/ssl/certs/statmagic.crt
COPY statmagic.key /etc/ssl/private/statmagic.key

RUN a2enmod cgi headers ssl && \
    a2ensite 000-default
RUN ln -s /usr/bin/mapserv /usr/lib/cgi-bin/mapserv

RUN mkdir -p /var/www/mapfiles && \
    mkdir -p /var/log/mapserver && \
    chown www-data.www-data /var/log/mapserver && \
    chown www-data /var/log/mapserver

ENTRYPOINT ["apache2ctl", "-D", "FOREGROUND"]