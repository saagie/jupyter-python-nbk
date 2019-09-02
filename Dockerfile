FROM saagie/jupyter-python-nbk:latest

# Default: run without authentication
CMD ["sh", "-c", "start-notebook.sh --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.base_url=$SAAGIE_BASE_PATH"]
