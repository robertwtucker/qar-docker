# Quadient Archive & Retrieval (IBM CMOD)
#  - Full Text Search server
#
# Base image
FROM registry.access.redhat.com/ubi8/ubi:8.7-1112

# Labels
LABEL "provider"="Quadient Group AG" \
      "volume.work"="/opt/qar/tmp"   \
      "port.fts-listener"="9181"

# Build Arguments
ARG INSTALL_FILES_URL

# Init values for CMOD (to be overwritten on container start, if needed).
ENV ARS_DB_ENGINE="ORACLE"                      \
    ARS_FTI_EXPORT_POLL_DELAY=180               \
    ARS_FULL_TEXT_INDEX_TOKEN=""                \
    ARS_HOST=""                                 \
    ARS_LOCAL_SRVR=""                           \
    ARS_NUM_DBSRVR=12                           \
    ARS_PORT=1445                               \
    ARS_SRVR_INSTANCE=QAR                       \
    ARS_STORAGE_MANAGER=NO_TSM                  \
    ARS_SRVR=""                                 \
    ARS_SUPPORT_FULL_TEXT_INDEX=0               \
    ENABLE_TRACE=FALSE                          \
    INSTALL_FILES_URL=$INSTALL_FILES_URL        \
    ODFTS_HOME=/opt/ibm/odfts/V10.5             \
    OD_HOME=/opt/ibm/ondemand/V10.5             \
    OD_INSTANCE_NAME=ARCHIVE                    \
    ORACLE_HOME=/usr/lib/oracle/21/client64/lib \
    ORACLE_HOST=""                              \
    ORACLE_PORT=1521                            \
    ORACLE_SERVICE_NAME=""                      \
    ORACLE_USER=""                              \
    ORACLE_PASSWORD=""                          \
    QAR_HOME=/opt/qar                           \
    RUNTIME_USER=archive                        \
    RUNTIME_USER_UID=1001

# -- Copy install files.
COPY od/*-response.file /tmp/odinst/

# -- Install packages, remove files when complete.
RUN dnf install -y wget procps \
 && wget -O /tmp/odinst/odftslinux.bin ${INSTALL_FILES_URL}/od/odftslinux.bin \
 && wget -O /tmp/odinst/odlinux.bin ${INSTALL_FILES_URL}/od/odlinux.bin \
 && wget -O /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin ${INSTALL_FILES_URL}/od/SP-SVR-10.5.0.5-Linux.bin \
 && wget -O /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
 && wget -O /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskssl64-8.0.55.12.linux.x86_64.rpm  \
 && wget -O /tmp/odinst/ojdbc11-full.tar.gz ${INSTALL_FILES_URL}/oracle/ojdbc11-full.tar.gz \
 && chmod a+x /tmp/odinst/*.bin \
 && /tmp/odinst/odftslinux.bin -i silent -f /tmp/odinst/odfts-response.file \
 && /tmp/odinst/odlinux.bin -i silent -f /tmp/odinst/od-response.file \
 && /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin -i silent -f /tmp/odinst/od-response.file  \
 && dnf localinstall -y /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
                        /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm \
 && mkdir -p /opt/oracle && tar -xof /tmp/odinst/ojdbc11-full.tar.gz -C /opt/oracle \
 && ln -s /opt/oracle/ojdbc11-full/ojdbc11.jar /opt/ibm/ondemand/V10.5/jars/jdbc1.jar \
 && chmod -R go+rx /opt/oracle && dnf clean all && rm -rf /tmp/odinst

ENV INSTALL_FILES_URL=""

# -- Add QAR home files.
ADD --chown=${RUNTIME_USER_UID}:0 qar-home.tar /opt

# Add runtime user, prepare file system.
RUN useradd -u ${RUNTIME_USER_UID} ${RUNTIME_USER} \
 && chmod -R a+x ${QAR_HOME}/docker/fts-entrypoint.sh ${QAR_HOME}/scripts/ \
 && cp -r ${QAR_HOME}/config/od/* ${OD_HOME}/config \
 && chown -R ${RUNTIME_USER_UID}:0 ${OD_HOME}/config ${ODFTS_HOME}

USER ${RUNTIME_USER}
EXPOSE 9181
ENTRYPOINT ["/opt/qar/docker/fts-entrypoint.sh"]
CMD ["start"]
