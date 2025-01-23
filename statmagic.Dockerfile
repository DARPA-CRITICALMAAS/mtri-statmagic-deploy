FROM ubuntu:22.04

ARG BASE_DIR=/usr/local/project
ARG WEBSITE_NAME=mtri-statmagic-web
ENV WEBSITE_NAME=${WEBSITE_NAME}

ARG DJANGO_USER_STATMAGIC_PGPASS
ARG CDR_API_TOKEN

# Create statmagic user
RUN useradd -m -s /bin/bash statmagic
RUN echo "statmagic:${DJANGO_USER_STATMAGIC_PGPASS}" | chpasswd
RUN chmod 755 /home/statmagic

# Add apache2, mod_wsgi, python3.6 libraries
RUN apt-get update && apt-get install -y apache2 \
    libapache2-mod-wsgi-py3 \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3.10-dev \
    python3.10 \
    python3.10-venv \
    python3-pip \
    vim \
    sudo \
    binutils \
    libproj-dev \
    gdal-bin \
    libgdal-dev \
    git \
    curl \
    wget \
    libgeos-dev \
    cron \
    mapserver-bin \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Make directory for base_site
RUN mkdir -p ${BASE_DIR}/${WEBSITE_NAME}
COPY $WEBSITE_NAME ${BASE_DIR}/${WEBSITE_NAME}

RUN mkdir -p /usr/local/pythonenv
RUN sudo pip3 install virtualenv
RUN virtualenv /usr/local/pythonenv/mtri-statmagic-web-env
RUN . /usr/local/pythonenv/mtri-statmagic-web-env/bin/activate && \
    cd ${BASE_DIR}/${WEBSITE_NAME} && \
    pip install --upgrade pip wheel && \
    pip install --no-cache-dir -r requirements.txt && \
#    pip install GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}') && \
#    pip install GDAL==3.4.0 && \
    cd ../ && \
    git clone https://github.com/DARPA-CRITICALMAAS/cdr_schemas.git && \
    cd cdr_schemas && \
    pip install -e .

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

# Copy apache config and docker entrypoint
COPY statmagic_000-default.conf /etc/apache2/sites-available/000-default.conf
COPY startup.sh /usr/local/project/startup.sh

# Enable required apache modules
RUN a2enmod cgi headers wsgi ssl && \
    a2ensite 000-default

# Expose port 80 on the container
#EXPOSE 80

# Environment manipulation required for apache
COPY .env /.env
RUN cat .env >> /etc/environment

# Set up CRON job to sync data layers from CDR, another job to force recreation of mapfile every 5 minutes
RUN mkdir -p /var/log/statmagic
RUN echo '*/1 * * * * export SECRET_KEY=secret;/usr/local/pythonenv/mtri-statmagic-web-env/bin/python /usr/local/project/mtri-statmagic-web/data_management_scripts/cron/sync_cdr_output_to_outputlayer_cron.py > /var/log/statmagic/sync_cdr_output_to_outputlayer_cron.log 2>&1' > /tmp/crontab.jobs && \
    echo '*/5 * * * * /usr/local/pythonenv/mtri-statmagic-web-env/bin/python /usr/local/project/mtri-statmagic-web/data_management_scripts/create_mapfile.py > /var/log/statmagic/create_mapfile.log 2&>1' >> /tmp/crontab.jobs && \
    crontab /tmp/crontab.jobs

ENTRYPOINT ["/bin/bash", "/usr/local/project/startup.sh"]