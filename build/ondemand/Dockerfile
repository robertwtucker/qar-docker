# Quadient Archive & Retrieval (IBM CMOD)
#  - Library Server including PDF Indexer
#  - Supports deployment as ARSLOAD Server
#  - Adapted in large part from the document at
#    https://www.ibm.com/support/pages/system/files/inline-files/Content%20Manager%20OnDemand%20Docker%202022-06-30.pdf
#
# Base image
FROM registry.access.redhat.com/ubi8/ubi:latest

# Labels
LABEL "provider"="Quadient Group AG"      \
      "volume.data"="/opt/qar/data"       \
      "volume.load"="/opt/qar/data/load"  \
      "volume.work"="/opt/qar/tmp"        \
      "port.ars-listener"="1445"

# Build Arguments
ARG INSTALL_FILES_URL

# Init values for CMOD (to be overwritten on container start, if needed).
ENV ARS_DB_ENGINE="ORACLE"                      \
    ARS_FULL_TEXT_INDEX_TOKEN=""                \
    ARS_HOST=""                                 \
    ARS_LOCAL_SRVR=""                           \
    ARS_NUM_DBSRVR=12                           \
    ARS_PORT=1445                               \
    ARS_SRVR_INSTANCE=QAR                       \
    ARS_STORAGE_MANAGER=NO_TSM                  \
    ARS_SRVR=""                                 \
    ARS_SUPPORT_FULL_TEXT_INDEX=0               \
    ARSLOAD_DIRECTORY="/opt/qar/data/load"      \
    ARSLOAD_PASSWORD=""                         \
    ARSLOAD_PERIOD="600"                        \
    ARSLOAD_USER=""                             \
    ENABLE_TRACE=FALSE                          \
    INSTALL_FILES_URL=$INSTALL_FILES_URL        \
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
    RUNTIME_USER_UID=1001                       \
    ZOOKEEPER_SERVER_LIST=""

# -- Copy install files.
COPY od/*-response.file /tmp/odinst/

# -- Install packages, remove files when complete.
RUN dnf install -y wget procps \
 && wget -O /tmp/odinst/odlinux.bin ${INSTALL_FILES_URL}/od/odlinux.bin \
 && wget -O /tmp/odinst/odpdflinux.bin ${INSTALL_FILES_URL}/od/odpdflinux.bin \
 && wget -O /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin ${INSTALL_FILES_URL}/od/SP-SVR-10.5.0.5-Linux.bin \
 && wget -O /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
 && wget -O /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskssl64-8.0.55.12.linux.x86_64.rpm  \
 && wget -O /tmp/odinst/oracle-instantclient-basic-21.8.0.0.0-1.el8.x86_64.rpm ${INSTALL_FILES_URL}/oracle/oracle-instantclient-basic-21.8.0.0.0-1.el8.x86_64.rpm \
 && wget -O /tmp/odinst/oracle-instantclient-sqlplus-21.8.0.0.0-1.el8.x86_64.rpm ${INSTALL_FILES_URL}/oracle/oracle-instantclient-sqlplus-21.8.0.0.0-1.el8.x86_64.rpm \
 && chmod +x /tmp/odinst/*.bin  \
 && /tmp/odinst/odlinux.bin -i silent -f /tmp/odinst/od-response.file \
 && /tmp/odinst/odpdflinux.bin -i silent -f /tmp/odinst/odpdf-response.file  \
 && /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin -i silent -f /tmp/odinst/od-response.file  \
 && dnf localinstall -y /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
                        /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm \
                        /tmp/odinst/oracle-instantclient-basic-21.8.0.0.0-1.el8.x86_64.rpm \
                        /tmp/odinst/oracle-instantclient-sqlplus-21.8.0.0.0-1.el8.x86_64.rpm \
 && dnf clean all && rm -rf /tmp/odinst

ENV INSTALL_FILES_URL=""

# -- Add QAR home files.
ADD --chown=${RUNTIME_USER_UID}:0 qar-home.tar /opt

# Add runtime user, prepare file system.
RUN useradd -u ${RUNTIME_USER_UID} ${RUNTIME_USER} \
 && chmod -R +x ${QAR_HOME}/docker/entrypoint.sh ${QAR_HOME}/scripts/ \
 && cp -r ${QAR_HOME}/config/od/* ${OD_HOME}/config \
 && cp -r ${QAR_HOME}/config/oracle/* ${ORACLE_HOME}/network/admin \
 && chown -R ${RUNTIME_USER_UID}:0 ${OD_HOME}/config ${ORACLE_HOME}/network/admin

USER ${RUNTIME_USER}
EXPOSE 1445
ENTRYPOINT ["/opt/qar/docker/entrypoint.sh"]
CMD ["start"]
