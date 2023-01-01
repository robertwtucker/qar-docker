# Quadient Archive & Retrieval (IBM CMOD)
#  - REST API provider
#
# Base image
FROM ibmcom/websphere-liberty:22.0.0.11-full-java11-openj9-ubi

# Labels
LABEL "provider"="Quadient Group AG"                \
      "volume.restcfg"="/opt/qar/tmp/restcfg"       \
      "volume.odpool"="/opt/qar/config/rest/odpool" \
      "port.http-listener"="9080"

# Build Arguments
ARG INSTALL_FILES_URL

# Init values for CMOD (to be overwritten on container start, if needed).
ENV OD_HOME=/opt/ibm/ondemand/V10.5                           \
    QAR_HOME=/opt/qar                                         \
    LD_LIBRARY_PATH=/opt/ibm/ondemand/V10.5/www               \
    WLP_DEFAULT_SERVER=/opt/ibm/wlp/usr/servers/defaultServer \
    WLP_RUNTIME_USER=default                                  \
    WLP_RUNTIME_USER_UID=1001                                 \
    OD_INSTANCE_NAME=""                                       \
    OD_USER=""                                                \
    OD_PASSWORD=""                                            \
    OD_HOST=""                                                \
    OD_PORT=""                                                \
    INSTALL_FILES_URL=${INSTALL_FILES_URL}

USER root

# -- Copy install files.
COPY od/*-response.file /tmp/odinst/

# -- Install packages, remove files when complete.
RUN dnf install -y wget \
 && wget -O /tmp/odinst/odlinux.bin ${INSTALL_FILES_URL}/od/odlinux.bin \
 && wget -O /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin ${INSTALL_FILES_URL}/od/SP-SVR-10.5.0.5-Linux.bin \
 && wget -O /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
 && wget -O /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm ${INSTALL_FILES_URL}/gskit/gskssl64-8.0.55.12.linux.x86_64.rpm \
 && wget -O /tmp/odinst/gskcrypt32-8.0.55.12.linux.x86.rpm ${INSTALL_FILES_URL}/gskit/gskcrypt32-8.0.55.12.linux.x86.rpm \
 && wget -O /tmp/odinst/gskssl32-8.0.55.12.linux.x86.rpm ${INSTALL_FILES_URL}/gskit/gskssl32-8.0.55.12.linux.x86.rpm \
 && chmod +x /tmp/odinst/*.bin \
 && /tmp/odinst/odlinux.bin -i silent -f /tmp/odinst/od-response.file \
 && /tmp/odinst/SP-SVR-10.5.0.5-Linux.bin -i silent -f /tmp/odinst/od-response.file \
 && dnf localinstall -y /tmp/odinst/gskcrypt64-8.0.55.12.linux.x86_64.rpm \
                        /tmp/odinst/gskssl64-8.0.55.12.linux.x86_64.rpm   \
                        /tmp/odinst/gskcrypt32-8.0.55.12.linux.x86.rpm    \
                        /tmp/odinst/gskssl32-8.0.55.12.linux.x86.rpm      \
 && dnf clean all && rm -rf /tmp/odinst

ENV INSTALL_FILES_URL=""

# -- Add QAR home files.
ADD --chown=${WLP_RUNTIME_USER_UID}:0 qar-home.tar /opt

USER ${WLP_RUNTIME_USER}

# -- Prepare files
RUN cp ${OD_HOME}/www/rest/cmod-rest.war ${WLP_DEFAULT_SERVER}/apps/ \
 && cp ${QAR_HOME}/config/rest/server.xml ${WLP_DEFAULT_SERVER}/server.xml \
 && chmod -R +x ${QAR_HOME}/scripts/ \
 && echo -e "\nrestcfgdir=${QAR_HOME}/tmp/restcfg" >> ${WLP_DEFAULT_SERVER}/server.env
