#!/bin/env bash
set -euo pipefail

# Deploy existing configration
deployConfig() {
  echo "Deploying stored configuration."

  # Un-tar the base64-encoded configuration file in the appropriate location
  base64 -d "${RESTCFG_FILE}" | tar -xv -C "${RESTCFG_WORK}"
}

# Generate new configuration
generateConfig() {
  echo "Generating REST API configuration."

  RESTCFG_DIR="${RESTCFG_WORK}"/restcfg
  TEMPLATE_FILE=default.tmpl

  # Create the REST config directory and copy the template file
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar setup -configDir "${RESTCFG_DIR}"
  cp "${QAR_HOME}"/config/rest/"${TEMPLATE_FILE}" "${RESTCFG_DIR}"

  # Populate the template file with instance parameters
  sed -i "s|odHost=|odHost=${OD_HOST}|" "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odPort=|odPort=${OD_PORT}|" "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odUser=|odUser=${OD_USER}|" "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odPassword=|odPassword=${OD_PASSWORD}|" "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odInstance=|odInstance=${OD_INSTANCE_NAME}|" "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"

  # Generate a REST connection pool
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar createPool \
    -configDir "${RESTCFG_DIR}" \
    -template "${TEMPLATE_FILE}" \
    -odInstance "${OD_INSTANCE_NAME}" \
    -odPassword "${OD_PASSWORD}" \
    -poolName "${REST_POOL_NAME}" \
    -odUser "${OD_USER}"

  # Create an access key for the named user
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar generateKey \
    -configDir "${RESTCFG_DIR}" \
    -poolName "${REST_POOL_NAME}" \
    -consumerName "${REST_CONSUMER_NAME}"

  # Remove the template file (has unencrypted password in it) before createing
  # a base64-encoded tar file with the configuration.
  rm -f "${RESTCFG_DIR}"/"${TEMPLATE_FILE}"
  ENCODED_FILE="${RESTCFG_WORK}"/restcfg.enc
  tar -cv -C "${RESTCFG_WORK}" restcfg | base64 -w 0 >"${ENCODED_FILE}"

  # Store the encoded configuration in the ConfigMap
  SERVICE_ACCOUNT="/var/run/secrets/kubernetes.io/serviceaccount"
  NAMESPACE=$(cat "${SERVICE_ACCOUNT}/namespace")
  curl -sS \
    -X PATCH \
    -H "Authorization: Bearer $(cat ${SERVICE_ACCOUNT}/token)" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json-patch+json" \
    --cacert "${SERVICE_ACCOUNT}/ca.crt" \
    --data "[{\"op\":\"replace\",\"path\":\"/data\",\"value\":{\"restcfg.enc\":\"$(cat "${ENCODED_FILE}")\"}}]" \
    "https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${NAMESPACE}/configmaps/${RESTCFG_NAME}"

  echo -e "\nFinished generating REST API configuration."
}

# --
# -- Main
# --

RESTCFG_FILE="${QAR_HOME}"/config/rest/stored/restcfg.enc
RESTCFG_WORK="${QAR_HOME}"/config/rest/work

# Test for run conditions
if [ -e "${RESTCFG_FILE}" ]; then
  deployConfig
else
  generateConfig
fi
