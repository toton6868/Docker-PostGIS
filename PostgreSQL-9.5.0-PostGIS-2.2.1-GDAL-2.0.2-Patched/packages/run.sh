#!/bin/bash

# Dependant env variables
LANG=${LOCALE}.${ENCODING}


# Check if data folder is empty. If it is, start the dataserver
if ! [ -f "${POSTGRES_DATA_FOLDER}/postgresql.conf" ]; then
    # Modify data store
    chown postgres:postgres ${POSTGRES_DATA_FOLDER}
    chmod 700 ${POSTGRES_DATA_FOLDER}

    # Create backups folder
    mkdir -p ${POSTGRES_BACKUPS_FOLDER}
    chown postgres:postgres ${POSTGRES_BACKUPS_FOLDER}
    chmod 700 ${POSTGRES_BACKUPS_FOLDER}
    
    # Create datastore
    su postgres -c "initdb --encoding=${ENCODING} --locale=${LANG} --lc-collate=${LANG} --lc-monetary=${LANG} --lc-numeric=${LANG} --lc-time=${LANG} -D ${POSTGRES_DATA_FOLDER}"
    
    # Modify basic configuration
    su postgres -c "echo \"host all all 0.0.0.0/0 md5\" >> $POSTGRES_DATA_FOLDER/pg_hba.conf"
    su postgres -c "echo \"listen_addresses='*'\" >> $POSTGRES_DATA_FOLDER/postgresql.conf"

    # Establish postgres user password and run the database
    su postgres -c "pg_ctl -w -D ${POSTGRES_DATA_FOLDER} start"
    su postgres -c "psql -h localhost -U postgres -p 5432 -c \"alter role postgres password '${POSTGRES_PASSWD}';\""

    # Check if CREATE_USER is not null
    if ! [ "$CREATE_USER" = "null" ]; then
	su postgres -c "psql -h localhost -U postgres -p 5432 -c \"create user ${CREATE_USER} with login password '${CREATE_USER_PASSWD}';\""
	su postgres -c "psql -h localhost -U postgres -p 5432 -c \"create database ${CREATE_USER} with owner ${CREATE_USER};\""
    fi

    # Run scripts
    python /usr/local/bin/run_psql_scripts

    # Stop the server
    su postgres -c "pg_ctl -w -D ${POSTGRES_DATA_FOLDER} stop"
fi


# Start the database
exec gosu postgres postgres -D $POSTGRES_DATA_FOLDER
