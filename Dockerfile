ARG PYTHON2_IMG="saagie/python:2.7.201912.65"
ARG PYTHON3_IMG="saagie/python:3.6.201912.65"
ARG BASE_CONTAINER="jupyter/scipy-notebook:c7fb6660d096"

FROM $PYTHON2_IMG AS PYTHON2
FROM $PYTHON3_IMG AS PYTHON3
FROM $BASE_CONTAINER

MAINTAINER Saagie


USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      libxml2-dev libxslt1-dev antiword unrtf poppler-utils pstotext tesseract-ocr \
      flac ffmpeg lame libmad0 libsox-fmt-mp3 sox libjpeg-dev swig redis-server libpulse-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install libraries dependencies
## For Debian we'll have to replace :
##   libpng3 => libpng-dev
##   libgdal1-dev => libgdal-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpng3 libfreetype6-dev libatlas-base-dev gfortran \
      libgdal1-dev libjpeg-dev sasl2-bin libsasl2-2 libsasl2-dev \
      libsasl2-modules unixodbc-dev python3-tk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pip2
RUN cd /tmp && wget https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py
# upgrade pip
RUN pip install --upgrade pip


USER $NB_USER
# Add python 2 kernel
RUN conda create -n ipykernel_py2 python=2 ipykernel --yes
RUN /bin/bash -c "source activate ipykernel_py2"
RUN python -m ipykernel install --user


USER root

# Install python2 libraries (not installed by python2 image)
RUN pip2 --no-cache-dir install \
    'dask==0.16.0' \
    'ipywidgets==7.0.5' \
    'vega==0.4.4' \
    'vincent==0.4.4' \
    'fastparquet==0.1.5' \
    'protobuf==3.6.1' \
  && rm -rf /root/.cachex


# Ask to update Conda but seems useless :
# Update conda to the latest version
# RUN conda update -n base conda


USER $NB_USER
# Add libraries and upgrade libraries installed in base image for python 3
## need to explicitely add qt/pyqt for debian it seems.
## RUN conda install qt pyqt
## also add condaforge
## RUN conda install -c conda-forge --quiet --yes \
RUN conda install --quiet --yes \
    'hdf5=1.10.1' \
    'python-hdfs=2.0.16' \
    'pillow=4.3.0' \
    'protobuf==3.6.1' \
    && conda remove --quiet --yes --force qt pyqt \
    && conda clean --all -y \
    && npm cache clean --force \
    && rm -rf $CONDA_DIR/share/jupyter/lab/staging

# fix-permissions should be used as root
USER root
RUN fix-permissions $CONDA_DIR

# Fix kernel config
#RUN python2 -m ipykernel install --user


########################## LIBS PART BEGIN ##########################
RUN apt update -qq && DEBIAN_FRONTEND=noninteractive apt install -qqy --no-install-recommends \
      qt5-default \
      libqt5webkit5-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*;
########################## LIBS PART END ##########################


########################## REQUIREMENTS PART BEGIN ##########################
# Import python2 libs from ...
COPY --from=PYTHON2 /requirements.txt ./requirements_python2.txt
RUN pip2 install -r requirements_python2.txt

# Import python3 libs from ...
COPY --from=PYTHON3 /requirements.txt ./requirements_python3.txt
RUN pip install -r requirements_python3.txt
########################## REQUIREMENTS PART END ##########################


# TODO check if necessary
########################## Fix ipykernel ##########################
USER root
RUN python2 -m ipykernel install --user
########################## Fix ipykernel END ##########################

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
