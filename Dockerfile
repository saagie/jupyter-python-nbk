ARG PYTHON2_IMG="saagie/python:2.7.201912.65"
ARG PYTHON3_IMG="saagie/python:3.6.201912.65"

# FIXME should use a minimal image and add libs after
ARG BASE_CONTAINER="jupyter/scipy-notebook:c7fb6660d096"

FROM $PYTHON2_IMG AS PYTHON2
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
########################## JUPYTER PIP2/PIP3 - PART BEGIN ##########################
# FIXME should install python2 explicitely
# Install pip2 & upgrade pip
RUN cd /tmp && wget https://bootstrap.pypa.io/get-pip.py \
    && python2 get-pip.py \
    && pip install --upgrade pip \
    && python2 -m pip install ipykernel

USER root
# Uninstall python2 kernel
RUN jupyter kernelspec remove -f python2
# Uninstall python3 kernel
RUN jupyter kernelspec remove -f python3

# Update conda to latest version
RUN conda update -n root conda

#RUN python2 -m ipykernel install --user --name py27 --display-name "Python 2.7"
RUN conda create -n py27 python=2.7 \
    && bash -c "source activate py27 && conda install notebook ipykernel -y && ipython kernel install --user --name py27 --display-name 'Python 2.7'"

#RUN python3 -m ipykernel install --user --name python3 --display-name "Python 3.6"
RUN conda create -n py36 python=3.6 \
    && bash -c "source activate py36 && pip uninstall pyzmq -y && pip install pyzmq && conda install notebook ipykernel -y && ipython kernel install --user --name py36 --display-name 'Python 3.6'"
########################## JUPYTER PIP2/PIP3 - PART EN ##########################


########################## REQUIREMENTS PART BEGIN ##########################
SHELL ["/bin/bash", "-c"]

# Import python2 libs from saagie/ptyhon:2.7
COPY --from=PYTHON2 /requirements.txt ./requirements_python2.txt
RUN . activate py27 && \
    python -m pip install --no-cache-dir -r requirements_python2.txt

# Import python3 libs from saagie/python:3.6
COPY --from=PYTHON3 /requirements.txt ./requirements_python3.txt
RUN  . activate py36 \
    && sed -n '/scikit-learn/p' requirements_python3.txt >> requirements_python3_ignore-installed.txt \
    && sed -i '/scikit-learn/d' requirements_python3.txt \
# Some installed library (scikit-learn) could not be removed so use --ignore-installed \
    && python -m pip install --no-cache-dir --ignore-installed -r requirements_python3_ignore-installed.txt \
    && python -m pip install --no-cache-dir -r requirements_python3.txt

# Install python2 libraries (not installed by python2 image)
COPY requirements_pip2.txt requirements_pip2.txt
RUN . activate py27 && \
    python -m pip install --no-cache-dir -r requirements_pip2.txt

# Add libraries and upgrade libraries installed in base image for python 3
COPY requirements_pip3.txt requirements_pip3.txt
RUN . activate py36 && \
    python -m pip install --no-cache-dir -r requirements_pip3.txt

# Add libraries with conda to conda2.7 env
COPY requirements_conda.txt requirements_conda2.txt
RUN conda install -n py27 --quiet --yes --file requirements_conda2.txt

# Add libraries with conda to conda3.6 env
COPY requirements_conda.txt requirements_conda3.txt
RUN conda install -n py36 --quiet --yes --file requirements_conda3.txt
########################## REQUIREMENTS PART END ##########################

# Clean
# Is this useless
#RUN conda remove --quiet --yes --force qt pyqt \
# conda clean does nothin
RUN conda clean --all -y \
# clears npm cache
    && npm cache clean --force \
    && rm -rf $CONDA_DIR/share/jupyter/lab/staging


########################## Fix ipykernel ##########################
# Without these lines jupyter uses python3 instead even for python2 sheets
# RUN python2 -m ipykernel install --user
########################## Fix ipykernel END ##########################
# see https://ipython.readthedocs.io/en/5.2.1/install/kernel_install.html


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
