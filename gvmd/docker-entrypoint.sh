#!/bin/bash

set -e

if [ "${1:0:1}" = '-' ]; then
    set -- gvmd "$@"
fi

if [ "$1" = 'gvmd' ]; then
    gvm-manage-certs -q -a &> /dev/nul || true

    if [ -z "${SKIP_WAIT_DB}" ]; then
	echo "waiting for the database..."
	while ! psql -q "${GVMD_POSTGRESQL_URI}" < /dev/null &> /dev/nul; do
	    sleep 1;
	done
    fi

    if [ "${FORCE_DB_INIT}" = "1" ] || [ ! -e /var/lib/gvm/.db-init ]; then
	echo "running db initializion script..."
	psql -f/usr/share/dbconfig-common/data/gvmd-pg/install-dbadmin/pgsql "${GVMD_POSTGRESQL_URI}"

	echo "migrating the database..."
	gvmd --migrate

	touch /var/lib/gvm/.db-init
    fi

    if [ -n "${GVMD_USER}" ] && ! gvmd --get-users | grep -q "${GVMD_USER}"; then
	echo "creating ${GVMD_USER} user..."
	gvmd --create-user="${GVMD_USER}" --role="${GVMD_USER_ROLE:-Admin}"
	gvmd --user="${GVMD_USER}" --new-password="${GVMD_PASSWORD:-${GVMD_USER}}"
    fi
fi

exec "$@"
