ARG PYTHON3_IMG="saagie/python:3.6.201912.65"
ARG BASE_CONTAINER="jupyter/scipy-notebook:c7fb6660d096"

FROM $PYTHON3_IMG AS PYTHON3
FROM $BASE_CONTAINER

MAINTAINER Saagie

ENV PATH=$PATH:/home/$NB_USER/.local/bin

USER root
########################## LIBS PART BEGIN ##########################
RUN apt-get update && apt-get install -y --no-install-recommends \
      libxml2-dev libxslt1-dev antiword unrtf poppler-utils pstotext tesseract-ocr \
      flac ffmpeg lame libmad0 libsox-fmt-mp3 sox libjpeg-dev swig redis-server libpulse-dev \
      libpng3 libfreetype6-dev libatlas-base-dev gfortran \
      libgdal1-dev sasl2-bin libsasl2-2 libsasl2-dev \
      libsasl2-modules unixodbc-dev python3-tk \
      qt5-default \
      libqt5webkit5-dev \
      libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
########################## LIBS PART END ##########################

USER $NB_USER

# Add libraries and upgrade libraries installed in base image for python 3
COPY requirements_conda.txt requirements_conda.txt
RUN conda install --quiet --yes --file requirements_conda.txt \
    && conda remove --quiet --yes --force qt pyqt \
    && conda clean --all -y \
    && npm cache clean --force \
    && rm -rf $CONDA_DIR/share/jupyter/lab/staging

# fix-permissions should be used as root
USER root
RUN fix-permissions $CONDA_DIR
########################## PTYHON2 / CONDA PART END ##########################

USER $NB_USER

########################## NOTEBOOKS DIR ##########################
USER root
# Create default workdir (useful if no volume mounted)
RUN mkdir /notebooks-dir && chown 1000:100 /notebooks-dir
# Add permission on /usr/local/lib/python2.7/ to allow Jovyan to 'pip2 install'
RUN chown -R $NB_USER:users /usr/local/lib/python2.7/
# Define default workdir
WORKDIR /notebooks-dir
########################## NOTEBOOKS DIR  END ##########################

# Should run as $NB_USER
USER $NB_USER

#Add entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
# Default: run without authentication
CMD ["/entrypoint.sh"]
