FROM ubuntu:22.04

MAINTAINER hbeadles

ARG BASE_DIR=/usr/local/project
ARG WEBSITE_NAME=mtri-statmagic-web
ENV WEBSITE_NAME=${WEBSITE_NAME}

ARG DJANGO_USER_STATMAGIC_PGPASS

# Create statmagic user
RUN useradd -m -s /bin/bash statmagic
RUN echo "statmagic:${DJANGO_USER_STATMAGIC_PGPASS}" | chpasswd

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
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod cgi headers wsgi

# Expose port 80 on the container
EXPOSE 80
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
    pip install GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}') && \
    cd ../ && \
    git clone https://github.com/DARPA-CRITICALMAAS/cdr_schemas.git && \
    cd cdr_schemas && \
    pip install -e .

ENTRYPOINT ["/bin/bash", "/usr/local/project/startup.sh"]