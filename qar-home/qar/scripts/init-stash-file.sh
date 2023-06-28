#!/usr/bin/env bash
set -euo pipefail

# Delete existing stash file (if any).
if [ -e "${OD_STASH_FILE}" ]; then
  echo "Deleting existing stash file..."
  rm -f "${OD_STASH_FILE}"
fi

# Create a new stash file.
echo "Creating stash for initial user (${OD_USER})..."
"${OD_HOME}"/bin/arsstash -a 1 -c \
  -s "${OD_STASH_FILE}" \
  -u "${OD_USER}" \
  -p "${OD_PASSWORD}"
echo "Stash file created successfully at ${OD_STASH_FILE}."

# Add Zookeeper credentials, if applicable.
if [ -n "${ZK_USER}" ] && [ -n "${ZK_PASSWORD}" ]; then
  echo "Stashing credentials for the Zookeeper user (${ZK_USER})..."
  "${OD_HOME}"/bin/arsstash -a 10 \
    -s "${OD_STASH_FILE}" \
    -u "${ZK_USER}" \
    -p "${ZK_PASSWORD}"
fi

echo -e "\nDone."
