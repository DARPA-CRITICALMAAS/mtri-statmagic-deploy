FROM ubuntu:22.04

RUN apt update && apt install -y \
    apache2 \
    mapserver-bin \
    libapache2-mod-fcgid

RUN a2enmod cgi headers
RUN ln -s /usr/bin/mapserv /usr/lib/cgi-bin/mapserv

RUN mkdir -p /var/www/mapfiles && \
    mkdir -p /var/log/mapserver && \
    chown www-data.www-data /var/log/mapserver && \
    chown www-data /var/log/mapserver

ENTRYPOINT ["apache2ctl", "-D", "FOREGROUND"]