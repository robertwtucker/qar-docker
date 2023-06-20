#!/bin/env bash
set -euo pipefail

# Initialize Oracle DB
initDatabase() {
  echo "Checking database for existence of the ARSSYS table"
  TABLE_COUNT=$(echo -e "SET HEADING OFF\n \
    SELECT COUNT(table_name) FROM user_tables WHERE table_name='ARSSYS';" |
    (sqlplus -S -m 'csv on' "${ORACLE_USER}/${ORACLE_PASSWORD}@${ARS_SRVR_INSTANCE}") ||
    echo "Could not connect to database")
  echo "ARSSYS table count is ${TABLE_COUNT}"
  if [ "${TABLE_COUNT}" == "0" ]; then
    echo "Creating the database instance"
    "${OD_HOME}"/bin/arsdb -rtv
    echo "Creating the system logging facility"
    "${OD_HOME}"/bin/arssyscr -I "${OD_INSTANCE_NAME}" -l
    echo "Creating the system load logging facility"
    "${OD_HOME}"/bin/arssyscr -I "${OD_INSTANCE_NAME}" -a
  else
    echo "Database initialization skipped"
  fi
}

# Start the ARSLOAD service
startLoad() {
  echo "Stashing ARSLOAD user's password"
  "${OD_HOME}"/bin/arsstash -a 3 \
    -s "${OD_STASH_FILE}" \
    -u "${ARSLOAD_USER}" \
    -p "${ARSLOAD_PASSWORD}"

  echo "Starting ARSLOAD service"
  "${OD_HOME}"/bin/arsload -v \
    -h "${ARS_SRVR}" \
    -t "${ARSLOAD_PERIOD}" \
    -d "${ARSLOAD_DIRECTORY}" \
    -u "${ARSLOAD_USER}" \
    -p "${OD_STASH_FILE}" &
  #    -c /opt/qar/tmp \
  OD_PID="${!}"
}

# Start the Library service
startLibrary() {
  echo "Stashing database user's password"
  "${OD_HOME}"/bin/arsstash -a 9 \
    -s "${OD_STASH_FILE}" \
    -u "${ORACLE_USER}" \
    -p "${ORACLE_PASSWORD}"

  initDatabase
  # Check/create dirs in case an empty volume is mounted to /data location
  for dir in ${QAR_HOME}/data/{cache,store}; do
    [ ! -d "${dir}" ] && mkdir -p "${dir}"
  done
  echo "Starting ARSSOCKD service (library server)"
  "${OD_HOME}"/bin/arssockd -v -S -I "${OD_INSTANCE_NAME}" &
  OD_PID="${!}"
}

stop() {
  echo "Received SIGINT or SIGTERM. Shutting down QAR"
  # Get PID
  local pid
  pid=$(cat /tmp/qar/run/od.pid)
  # Set TERM
  kill -SIGTERM "${pid}"
  # Wait for exit
  wait "${pid}"
  # All done
  echo "Done."
}

# --
# -- Main
# --

# Help CMOD find the Oracle shared libs
LD_LIBRARY_PATH=${ORACLE_HOME}
export LD_LIBRARY_PATH

# Make CMOD executables visible in the PATH
PATH=${PATH}:${OD_HOME}/bin
export PATH

# CMOD configuration
OD_CONFIG=${OD_HOME}/config
OD_STASH_FILE=${QAR_HOME}/tmp/od.stash
export OD_STASH_FILE

# ARS.CFG
sed -i "s|__ARS.CFG#ARS_SRVR__|${ARS_SRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_LOCAL_SRVR__|${ARS_LOCAL_SRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_NUM_DBSRVR__|${ARS_NUM_DBSRVR}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_DB_ENGINE__|${ARS_DB_ENGINE}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_ORACLE_HOME__|${ORACLE_HOME}|" "${OD_CONFIG}"/ars.cfg
sed -i "s|__ARS.CFG#ARS_STORAGE_MANAGER__|${ARS_STORAGE_MANAGER}|" "${OD_CONFIG}"/ars.cfg

if [ "${ENABLE_TRACE^^}" = "TRUE" ]; then
  sed -i "s|#ARS_TRACE_SETTINGS|ARS_TRACE_SETTINGS|" "${OD_CONFIG}"/ars.cfg
fi

if [ -n "${ZOOKEEPER_SERVER_LIST}" ]; then
  echo "Zookeeper deployment is active"
  sed -i "s|#ARS_LOCK_HOSTS=|ARS_LOCK_HOSTS=${ZOOKEEPER_SERVER_LIST}|" "${OD_CONFIG}"/ars.cfg
fi

FTS_TOKEN_FILE="${QAR_HOME}"/config/fti/fts.token
if [ -e "${FTS_TOKEN_FILE}" ]; then
  echo "Full-text indexing is enabled"
  ARS_SUPPORT_FULL_TEXT_INDEX=1
  ARS_FULL_TEXT_INDEX_TOKEN=$(cat "${FTS_TOKEN_FILE}")
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

# Oracle configuration
TNS_ADMIN=${ORACLE_HOME}/network/admin

sed -i "s|__TNS.ORA#INSTANCE__|${ARS_SRVR_INSTANCE}|" "${TNS_ADMIN}"/tnsnames.ora
sed -i "s|__TNS.ORA#HOST__|${ORACLE_HOST}|" "${TNS_ADMIN}"/tnsnames.ora
sed -i "s|__TNS.ORA#PORT__|${ORACLE_PORT}|" "${TNS_ADMIN}"/tnsnames.ora
sed -i "s|__TNS.ORA#SERVICE_NAME__|${ORACLE_SERVICE_NAME}|" "${TNS_ADMIN}"/tnsnames.ora

if [ "${1^^}" == "START" ]; then
  case ${2^^} in
  ARSLOAD)
    startLoad
    ;;
  LIBRARY)
    startLibrary
    ;;
  *)
    echo "Unknown or missing argument to start: \"${2:-}\""
    echo "Usage:  start [library|arsload]"
    exit 1
    ;;
  esac

  trap stop SIGINT SIGTERM
  mkdir -p /tmp/qar/run && echo "${OD_PID}" >/tmp/qar/run/od.pid
  wait "${OD_PID}" && exit $?
else
  exec "$@"
fi
