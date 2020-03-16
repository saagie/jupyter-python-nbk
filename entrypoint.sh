#!/bin/bash
chown -R jovyan /notebooks-dir

start-notebook.sh --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.base_url=$SAAGIE_BASE_PATH
