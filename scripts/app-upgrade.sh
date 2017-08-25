#!/bin/sh
set -e

START_TIME=$(date +%s)

echo "=== Starting database container. ==============================================="
docker-compose up -d db

echo "=== Starting web container. ===================================================="
docker-compose up -d web

echo "=== Starting backup container. ================================================="
docker-compose up -d backup

echo "=== Backing up application stack. =============================================="
docker-compose exec backup app-backup

echo "=== Removing currnet application stack. ========================================"
docker-compose down

echo "=== Pulling changes from repo. ================================================="
git pull

echo "=== Updating environment file. ================================================="
OLD_BITBUCKET_VERSION=$(grep ^BITBUCKET_VERSION= .env | cut -d = -f 2)
NEW_BITBUCKET_VERSION=$(grep ^BITBUCKET_VERSION= .env.template | cut -d = -f 2)
echo "[I] Upgrading Bitbucket from '$OLD_BITBUCKET_VERSION' to '$NEW_BITBUCKET_VERSION'."
sed -i .bak "s/^BITBUCKET_VERSION=.*/BITBUCKET_VERSION=$NEW_BITBUCKET_VERSION/g" .env

echo "=== Building new images. ======================================================="
docker-compose build --pull

echo "=== Pulling updated database image. ============================================"
docker-compose pull db

echo "=== Starting backup container. ================================================="
docker-compose up -d backup

echo "=== Restoring application stack to most recent backup. ========================="
cd backups
LATEST_BACKUP=$(ls -1tr *.tar.gz 2> /dev/null | tail -n 1)
cd ..
docker-compose exec backup app-restore $LATEST_BACKUP

END_TIME=$(date +%s)

echo "=== Upgrade complete. =========================================================="
echo "[I] Time elapsed: $((END_TIME-START_TIME)) seconds."
