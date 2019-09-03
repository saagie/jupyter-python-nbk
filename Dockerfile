FROM saagie/jupyter-python-nbk:latest
USER root
#Remove saagie plugin
RUN pip uninstall -y jupyter-saagie-plugin
RUN jupyter nbextension uninstall saagie --user
#Add entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
# Default: run without authentication
CMD ["/entrypoint.sh"]