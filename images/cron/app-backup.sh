#!/bin/sh
set -e

TIMESTAMP=$(date +%Y%m%dT%H%M%S%z)
START_TIME=$(date +%s)

cd "$HOST_PATH"

if [ "$BACKUP_OPERATION" = "disable" ]; then
    echo "[W] Backups are disabled."
else
    if [ ! -d backups ]; then
        echo "[I] Creating backup directory."
        mkdir backups
    fi

    if [ -d backups/tmp_backup ]; then
        echo "[W] Cleaning up from a previously-failed execution."
        rm -rf backups/tmp_backup
    fi

    echo "[I] Creating working directory."
    mkdir -p backups/tmp_backup

    echo "[I] Performing initial backup of Bitbucket home directory."
    rsync --archive --delete volumes/web/data/ backups/tmp_backup/home

    echo "[I] Locking Bitbucket instance."
    UNLOCK_TOKEN=$(curl --silent \
        --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
        --request POST \
        --header "Content-type: application/json" \
        "http://web:7990/mvc/maintenance/lock" \
      | jq --raw-output '.unlockToken')
    if [ "$UNLOCK_TOKEN" ]; then
        echo "[I] Successfully locked Bitbucket with the following token:"
        echo "      $UNLOCK_TOKEN"
    else
        echo "[E] Failed to lock Bitbucket instance."
        exit 1
    fi

    echo "[I] Closing Bitbucket connections."
    CANCEL_TOKEN=$(curl --silent \
        --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
        --request POST \
        --header "X-Atlassian-Maintenance-Token: ${UNLOCK_TOKEN}" \
        --header "Accept: application/json" \
        --header "Content-type: application/json" \
        "http://web:7990/mvc/admin/backups?external=true" \
      | jq --raw-output '.cancelToken')
    if [ "$CANCEL_TOKEN" ]; then
        echo "[I] Successfully started Bitbucket connection drain with the following token:"
        echo "      $CANCEL_TOKEN"
    else
        echo "[E] Failed to close Bitbucket connections."
        exit 1
    fi

    echo "[I] Waiting for Bitbucket to finish draining connections."
    while [ "$DB_STATE" != "DRAINED" -o "$DB_STATE" != "DRAINED" ]; do
        DRAIN_STATE=$(curl --silent \
            --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
            --request GET \
            --header "X-Atlassian-Maintenance-Token: ${UNLOCK_TOKEN}" \
            --header "Accept: application/json" \
            --header "Content-type: application/json" \
            "http://web:7990/mvc/maintenance")
        DB_STATE=$(echo $DRAIN_STATE | jq --raw-output '."db-state"')
        SCM_STATE=$(echo $DRAIN_STATE | jq --raw-output '."scm-state"')
        sleep 1
    done
    echo "[I] Successfully finished draining Bitbucket connections."

    echo "[I] Performing incremental backup of Bitbucket home directory."
    rsync --archive --delete volumes/web/data/ backups/tmp_backup/home

    echo "[I] Updating Bitbucket backup progress."
    curl --silent \
        --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
        --request POST \
        --header "Accept: application/json" \
        --header "Content-type: application/json" \
        "http://web:7990/mvc/admin/backups/progress/client?token=${UNLOCK_TOKEN}&percentage=50"

    echo "[I] Backing up Bitbucket database."
    PGPASSWORD=${POSTGRES_PASSWORD} pg_dump --host=db --username=${POSTGRES_USER} --dbname=${POSTGRES_DB} > backups/tmp_backup/db.sql

    echo "[I] Updating Bitbucket backup progress."
    curl --silent \
        --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
        --request POST \
        --header "Accept: application/json" \
        --header "Content-type: application/json" \
        "http://web:7990/mvc/admin/backups/progress/client?token=${UNLOCK_TOKEN}&percentage=100"

    echo "[I] Unlocking Bitbucket instance."
    curl --silent \
        --user ${BITBUCKET_USERNAME}:${BITBUCKET_PASSWORD} \
        --request DELETE \
        --header "Accept: application/json" \
        --header "Content-type: application/json" \
        "http://web:7990/mvc/maintenance/lock?token=${UNLOCK_TOKEN}"
    echo "[I] Successfully unlocked Bitbucket."

    echo "[I] Compressing backup."
    tar -zcf backups/$TIMESTAMP.tar.gz -C backups/tmp_backup .

    echo "[I] Removing working directory."
    rm -rf backups/tmp_backup

    EXPIRED_BACKUPS=$(ls -1tr backups/*.tar.gz 2>/dev/null | head -n -$BACKUP_RETENTION)
    if [ "$EXPIRED_BACKUPS" ]; then
        echo "[I] Cleaning up expired backup(s):"
        for BACKUP in $EXPIRED_BACKUPS; do
            echo "      $BACKUP"
            rm "$BACKUP"
        done
    fi
fi

END_TIME=$(date +%s)

echo "[I] Script complete. Time elapsed: $((END_TIME-START_TIME)) seconds."
