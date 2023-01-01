#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 2 ]; then
  OD_USER="${1^^}"
  OD_INSTANCE="${2^^}"
elif [ $# -eq 1 ]; then
  OD_USER="${1^^}"
  OD_INSTANCE="ARCHIVE"
else
  echo "Incorrect number of arguments."
  echo "Usage: import-xml.sh <user> [<od instance>:=ARCHIVE]"
  exit
fi
OD_USER_STASH_FILE="${QAR_HOME}"/tmp/"${OD_USER,,}".stash

# Delete existing stash file (if any)
if [ -e "${OD_USER_STASH_FILE}" ]; then
  rm -f "${OD_USER_STASH_FILE}"
fi

# Read password from stdin
read -srp "Password for ${OD_USER}: " OD_PASSWORD

# Create stash file w/user and password supplied
"${OD_HOME}"/bin/arsstash -c -s "${OD_USER_STASH_FILE}" -u "${OD_USER}" -p "${OD_PASSWORD}"

# Add the CMOD objects as described in the settings.xml file
echo "Adding the CMOD objects from the settings file (${QAR_HOME}/xml/settings.xml)."
"${OD_HOME}"/bin/arsxml add -eu -x -v \
  -h "${OD_INSTANCE}" \
  -i settings.xml \
  -d "${QAR_HOME}"/config/xml \
  -u "${OD_USER}" \
  -p "${OD_USER_STASH_FILE}"

echo "Done."
