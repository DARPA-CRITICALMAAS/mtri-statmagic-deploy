# Use an official Miniconda3 image as a parent image
#FROM continuumio/miniconda3:latest
FROM condaforge/miniforge3:latest

# Make Docker use bash instead of sh
SHELL ["/bin/bash", "--login", "-c"]

RUN mkdir -p /usr/local/project/
WORKDIR /usr/local/project/

# Configuration required for miniforge/licensing stuff
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    libgdal-dev \
    python3-pip


RUN git clone https://github.com/DARPA-CRITICALMAAS/beak-ta3.git

# Update conda
RUN conda update -n base -c defaults conda

# Create a Conda environment with specified name
RUN #conda env create -f beak-ta3/setup/docker/conda/environment.yml
RUN conda env create -f beak-ta3/setup/unix/environment.yml

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "beak-ta3", "/bin/bash", "-c"]

# Set new environment to default
ENV CONDA_DEFAULT_ENV=beak-ta3

# Update pip and install additional requirements
RUN pip install --upgrade \
        pip \
        wheel \
        ngrok \
        uvicorn \
        optuna \
        fastapi
RUN pip install -e beak-ta3/

#RUN git clone https://github.com/DARPA-CRITICALMAAS/mtri-statmagic-web.git
COPY mtri-statmagic-web/cdr/ /cdr/
RUN mkdir /beak_datalayer_cache

# Clean caches and temporary files
RUN conda clean --all -y
RUN pip cache purge
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#ENTRYPOINT ["/opt/conda/envs/beak-ta3/bin/python", "/usr/local/project/mtri-statmagic-web/cdr/subscriber_server.py"]
ENTRYPOINT ["/opt/conda/envs/beak-ta3/bin/python", "/cdr/subscriber_server.py"]
