#!/usr/bin/env bash
set -euo pipefail

case $# in
2)
  OD_USER="${1^^}"
  OD_INSTANCE="${2^^}"
  ;;
1)
  OD_USER="${1^^}"
  OD_INSTANCE="ARCHIVE"
  ;;
0)
  OD_USER="ADMIN"
  OD_INSTANCE="ARCHIVE"
  ;;
*)
  echo "Incorrect number of arguments."
  echo "Usage: set-admin-passwd.sh [<user>:=ADMIN] [<od instance>:=ARCHIVE]"
  exit
  ;;
esac
OD_USER_STASH_FILE="${QAR_HOME}"/tmp/"${OD_USER,,}".stash

# Delete existing stash file (if any)
if [ -e "${OD_USER_STASH_FILE}" ]; then
  rm -f "${OD_USER_STASH_FILE}"
fi

# Create stash file w/initial user (default: ADMIN) and expired password
"${OD_HOME}"/bin/arsstash -a 1 -c -s "${OD_USER_STASH_FILE}" -u ${OD_USER} -p ""

# Change password for the initial user (default: ADMIN)
echo -e "Initiating password change for user ${OD_USER} ...\n"
"${OD_HOME}"/bin/arsadmin change_password -h ${OD_INSTANCE} -u ${OD_USER} -p "${OD_USER_STASH_FILE}"
echo -e "\nDone."
