#!/usr/bin/env bash
set -euo pipefail

case $# in
1)
  CONSUMER="${1,,}"
  ;;
0)
  CONSUMER="admin"
  ;;
*)
  echo "Incorrect number of arguments."
  echo "Usage: get-rest-api-key.sh [<consumer>:=admin]"
  exit
  ;;
esac

# Parse the shared key (if found)
CONSUMER_KEY_FILE="${QAR_HOME}"/config/rest/work/restcfg/keys/"${CONSUMER}".ksf
if [ -e "${CONSUMER_KEY_FILE}" ]; then
  echo "CMODSharedKey $(awk -F= 'NR==2 {print $1}' "${CONSUMER_KEY_FILE}")"
else
  cat <<_EOM
${CONSUMER_KEY_FILE} not found.
Please check the consumer provided and ensure this script is running on a
QAR REST API server.
_EOM
fi
