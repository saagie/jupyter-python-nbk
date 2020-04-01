ARG PYTHON2_IMG="saagie/python:2.7.202003.76"
ARG PYTHON3_IMG="saagie/python:3.6.202003.76"

# FIXME should use a minimal image and add libs after
ARG BASE_CONTAINER="jupyter/scipy-notebook:c7fb6660d096"

FROM $PYTHON2_IMG AS PYTHON2
FROM $PYTHON3_IMG AS PYTHON3
FROM $BASE_CONTAINER

MAINTAINER Saagie

ENV PATH=$PATH:/home/$NB_USER/.local/bin


# Starts by cleaning useless npm cache
RUN npm cache clean --force


USER root
########################## LIBS PART BEGIN ##########################
# TODO check if all necessary
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
########################## Kernels - PART BEGIN ##########################
# Uninstall python3 kernel
RUN jupyter kernelspec remove -f python3
# Update conda to latest version
RUN conda update -n root conda
# Install python2.7 and 3.6 environments
RUN conda create -n py27 python=2.7 \
    && bash -c "source activate py27 && conda install notebook ipykernel -y && ipython kernel install --user --name py27 --display-name 'Python 2.7'" && \
    rm -rf ~/.cache/pip
# seems there's sometimesa problem with pyzmq so need to reinstall it...
RUN conda create -n py36 python=3.6 \
    && bash -c "source activate py36 && pip uninstall pyzmq -y && pip install pyzmq && conda install notebook ipykernel -y && ipython kernel install --user --name py36 --display-name 'Python 3.6'" && \
    rm -rf ~/.cache/pip
########################## Kernels - PART END ##########################


########################## REQUIREMENTS PART BEGIN ##########################
SHELL ["/bin/bash", "-c"]

# Add libs for python 2.7 env
#     inherited from saagie/python:2.7 image
#     installed via pip only
#     installed via conda
COPY requirements_conda.txt requirements_conda2.txt
COPY --from=PYTHON2 /requirements.txt ./requirements_python2.txt
COPY requirements_pip2.txt requirements_pip2.txt
RUN conda install -n py27 --quiet --yes --file requirements_conda2.txt && \
    . activate py27 && \
    python -m pip install --no-cache-dir -r requirements_python2.txt && \
    python -m pip install --no-cache-dir -r requirements_pip2.txt && \
    conda deactivate && \
    rm -rf ~/.cache/pip
# Add libs for python 3.6 env
#     inherited from saagie/python:3.6 image
#     installed via pip only
#     installed via conda
COPY requirements_conda.txt requirements_conda3.txt
COPY --from=PYTHON3 /requirements.txt ./requirements_python3.txt
COPY requirements_pip3.txt requirements_pip3.txt
RUN conda install -n py36 --quiet --yes --file requirements_conda3.txt && \
    # Some installed library (scikit-learn) could not be removed so use --ignore-installed \
    sed -n '/scikit-learn/p' requirements_python3.txt >> requirements_python3_ignore-installed.txt && \
    sed -i '/scikit-learn/d' requirements_python3.txt && \
    . activate py36 && \
    python -m pip install --no-cache-dir --ignore-installed -r requirements_python3_ignore-installed.txt && \
    python -m pip install --no-cache-dir -r requirements_python3.txt && \
    python -m pip install --no-cache-dir -r requirements_pip3.txt && \
    conda deactivate && \
    rm -rf ~/.cache/pip
########################## REQUIREMENTS PART END ##########################

# Clean
RUN conda clean --all -y \
    && rm -rf $CONDA_DIR/share/jupyter/lab/staging


########################## NOTEBOOKS DIR ##########################
USER root
# Create default workdir (useful if no volume mounted)
RUN mkdir /notebooks-dir && chown 1000:100 /notebooks-dir
# Define default workdir
WORKDIR /notebooks-dir
########################## NOTEBOOKS DIR  END ##########################

# Should run as $NB_USER
USER $NB_USER
#Add entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
# Default: run without authentication
CMD ["/entrypoint.sh"]
