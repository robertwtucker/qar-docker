#!/usr/bin/env bash
set -euo pipefail

# Handle trapped signals
stop() {
  echo "Received SIGINT or SIGTERM. Shutting down FTS"
  # Shut down FTI Server
  "${ODFTS_HOME}"/bin/shutdown.sh

  # Get FTI Export process ID
  local pid
  pid=$(cat /tmp/qar/run/fti.pid)
  # Set TERM
  kill -SIGTERM "${pid}"
  # Wait for exit
  wait "${pid}"

  # All done
  echo "Done."
}

start_exporter() {
  # Build classpath
  for file in "${OD_HOME}"/jars/*; do
    [ -e "${file}" ] || continue
    OD_JARS="${OD_JARS:-./}":"${file}"
  done

  # Change to writeable directory (logs to ./ by default)
  cd "${QAR_HOME}"/tmp

  # Configure export
  "${OD_HOME}"/jre/bin/java \
    -Dlog4j.configurationFile="${OD_HOME}"/jars/log4j2.xml \
    -cp "${OD_JARS}" \
    com.ibm.cm.od.fti.exporter.Export configure \
    -configFile "${QAR_HOME}"/tmp/fti.config \
    -dbEngine "${ARS_DB_ENGINE}" \
    -dbHostname "${ORACLE_HOST}" \
    -dbPort "${ORACLE_PORT}" \
    -dbUser "${ORACLE_USER}" \
    -dbPassword "${ORACLE_PASSWORD}" \
    -dbName "${ARS_SRVR_INSTANCE}" \
    -dbOwner "${ORACLE_USER}" \
    -odInstance "${OD_INSTANCE_NAME}" \
    -odUser "${OD_USER}" \
    -odPassword "${OD_PASSWORD}" \
    -odInstallDir "${OD_HOME}" \
    -pollDelay "${ARS_FTI_EXPORT_POLL_DELAY}" \
    -ftiToken "$(cat "${QAR_HOME}"/tmp/fts.token)"

  # Invoke export
  "${OD_HOME}"/jre/bin/java \
    -Djava.library.path="${OD_HOME}"/lib64:"${OD_HOME}"/www \
    -Dlog4j.configurationFile="${OD_HOME}"/jars/log4j2.xml \
    -classpath "${OD_JARS}" \
    com.ibm.cm.od.fti.exporter.Export index \
    -configFile "${QAR_HOME}"/tmp/fti.config &

  FTI_PID="${!}"
  mkdir -p /tmp/qar/run && echo "${FTI_PID}" >/tmp/qar/run/fti.pid
}

# --
# -- Main
# --

# CMOD configuration
OD_CONFIG=${OD_HOME}/config
OD_STASH_FILE=${QAR_HOME}/tmp/od.stash
export OD_STASH_FILE

# ARS.CFG
sed -i "s|__ARS.CFG#ARS_SRVR__|${ARS_SRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_LOCAL_SRVR__|${ARS_LOCAL_SRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_NUM_DBSRVR__|${ARS_NUM_DBSRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_DB_ENGINE__|${ARS_DB_ENGINE}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_STORAGE_MANAGER__|${ARS_STORAGE_MANAGER}|" "${OD_CONFIG}"/ars.cfg

if [ "${ENABLE_TRACE^^}" = "TRUE" ]; then
  sed -i "s|#ARS_TRACE_SETTINGS|ARS_TRACE_SETTINGS|" "${OD_CONFIG}"/ars.cfg
fi

FTS_TOKEN="${QAR_HOME}"/tmp/fts.token
if [ -e "${FTS_TOKEN}" ]; then
  echo "Full-text indexing is enabled"
  ARS_SUPPORT_FULL_TEXT_INDEX=1
  ARS_FULL_TEXT_INDEX_TOKEN=$(cat "${FTS_TOKEN}")
  export ARS_SUPPORT_FULL_TEXT_INDEX ARS_FULL_TEXT_INDEX_TOKEN
fi
sed -i "s|__ARS.CFG#ARS_SUPPORT_FULL_TEXT_INDEX__|${ARS_SUPPORT_FULL_TEXT_INDEX}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_FULL_TEXT_INDEX_TOKEN__|${ARS_FULL_TEXT_INDEX_TOKEN}|" "${OD_CONFIG}"/ars.cfg

# ARS.INI
sed -i "s|__ARS.INI#OD_INSTANCE_NAME__|${OD_INSTANCE_NAME^^}|" "${OD_CONFIG}"/ars.ini
sed -i "s|__ARS.INI#HOST__|${ARS_HOST}|" "${OD_CONFIG}"/ars.ini
sed -i "s|__ARS.INI#PORT__|${ARS_PORT}|" "${OD_CONFIG}"/ars.ini
sed -i "s|__ARS.INI#SRVR_INSTANCE__|${ARS_SRVR_INSTANCE}|" "${OD_CONFIG}"/ars.ini
sed -i "s|__ARS.INI#SRVR_INSTANCE_OWNER__|${RUNTIME_USER}|" "${OD_CONFIG}"/ars.ini
sed -i "s|__ARS.INI#SRVR_OD_STASH__|${OD_STASH_FILE}|" "${OD_CONFIG}"/ars.ini

if [ "${1^^}" = "INIT" ]; then
  echo "Starting FTS initialization"

  # Generate the FTS token
  echo "Generating FTS token..."
  TOKEN=$("${ODFTS_HOME}"/bin/configTool.sh printToken -configPath "${ODFTS_HOME}"/config | sed -n 2p)
  echo "${TOKEN}" >"${QAR_HOME}/tmp/fts.token"
  echo "Wrote token to ${QAR_HOME}/tmp/fts.token"

  # Store the PTS token in the ConfigMap
  echo "Patching configuration with token value..."
  SERVICE_ACCOUNT="/var/run/secrets/kubernetes.io/serviceaccount"
  NAMESPACE=$(cat "${SERVICE_ACCOUNT}/namespace")
  curl -sS \
    -X PATCH \
    -H "Authorization: Bearer $(cat ${SERVICE_ACCOUNT}/token)" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json-patch+json" \
    --cacert "${SERVICE_ACCOUNT}/ca.crt" \
    --data "[{\"op\":\"replace\",\"path\":\"/data\",\"value\":{\"token\":\"${TOKEN}\"}}]" \
    "https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIG_NAME}"

  echo -e "\nFTS initialization complete"
else
  if [ "${1^^}" = "START" ]; then
    echo "Starting FTS"

    # Start the FTI server
    "${ODFTS_HOME}"/bin/startup.sh

    # Start the FTI exporter
    start_exporter

    trap stop SIGINT SIGTERM
    sleep infinity &
    wait
  else
    exec "$@"
  fi
fi
