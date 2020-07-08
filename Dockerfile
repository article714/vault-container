FROM vault:latest
LABEL maintainer="C. Guychard @ Article714"


# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Container tooling

COPY container /container

# container building

RUN /container/build.sh


# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file
# LOGS  in external volume
VOLUME /var/log
# Configuration  in external volume
VOLUME /container/config

# entrypoint  & default command
ENTRYPOINT [ "/container/entrypoint.sh" ]
CMD ["start"]

# healthcheck
HEALTHCHECK --interval=120s --timeout=2s --retries=5 CMD /container/check_running