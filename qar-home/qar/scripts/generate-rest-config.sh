#!/bin/env bash
set -euo pipefail

# Deploy existing configration
deployConfig() {
  echo "${REST_CONFIG_TAR_FILE} exists. Deploying configuration."

  # Un-tar the configuration file in the appropriate location
  tar -xvf "${REST_CONFIG_TAR_FILE}" -C "${QAR_HOME}"/tmp
}

# Generate new configuration
generateConfig() {
  echo "${REST_CONFIG_TAR_FILE} does not exist. Generating configuration."

  # Create the REST config directory and copy the template file
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar setup -configDir "${REST_CONFIG_DIR}"
  cp "${QAR_HOME}"/config/rest/"${TEMPLATE_FILE}" "${REST_CONFIG_DIR}"

  # Populate the template file with instance parameters
  sed -i "s|odHost=|odHost=${OD_HOST}|" "${REST_CONFIG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odPort=|odPort=${OD_PORT}|" "${REST_CONFIG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odUser=|odUser=${OD_USER}|" "${REST_CONFIG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odPassword=|odPassword=${OD_PASSWORD}|" "${REST_CONFIG_DIR}"/"${TEMPLATE_FILE}"
  sed -i "s|odInstance=|odInstance=${OD_INSTANCE_NAME}|" "${REST_CONFIG_DIR}"/"${TEMPLATE_FILE}"

  # Generate the pool, save access keys and configuration
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar createPool \
    -configDir "${REST_CONFIG_DIR}" \
    -template "${TEMPLATE_FILE}" \
    -odInstance "${OD_INSTANCE_NAME}" \
    -odPassword "${OD_PASSWORD}" \
    -poolName odpool \
    -odUser "${OD_USER}"
  java -jar "${OD_HOME}"/jars/ODRESTAdmin.jar generateKey \
    -configDir "${REST_CONFIG_DIR}" \
    -poolName odpool \
    -consumerName "${OD_USER}" \
    >"${QAR_HOME}"/config/rest/odpool/"${OD_USER}".rest.credentials
  tar -cvf "${REST_CONFIG_TAR_FILE}" -C "/opt/qar/tmp" restcfg
}

# --
# -- Main
# --

# Define/export key variables
REST_CONFIG_DIR="${QAR_HOME}"/tmp/restcfg
TEMPLATE_FILE=default.tmpl
REST_CONFIG_TAR_FILE="${QAR_HOME}"/config/rest/odpool/restcfg.tar
export REST_CONFIG_DIR TEMPLATE_FILE REST_CONFIG_TAR_FILE

# Test for run conditions
if [ -e "${REST_CONFIG_TAR_FILE}" ]; then
  deployConfig
else
  generateConfig
fi
