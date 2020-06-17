#!/bin/bash
chown -R jovyan /notebooks-dir

TARGET_NAMESPACE="saagie1-projectc5aa8432-f94a-4707-bb9e-79e183e8b107"
FILE_KERNEL_PY27="/home/jovyan/.local/share/jupyter/kernels/py27/kernel.json"
FILE_KERNEL_PY36="/home/jovyan/.local/share/jupyter/kernels/py36/kernel.json"

# get line conatining env
# sed -n '/"env"/p' $FILE_KERNEL_PY36
# if line exists insert



start-notebook.sh --KernelSpecManager.ensure_native_kernel=False --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.base_url=$SAAGIE_BASE_PATH
