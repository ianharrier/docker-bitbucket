#!/bin/sh
set -e

# This script modifies itself after successfully preforming tasks, preventing
# the tasks from running every time the container is restarted.
PERMISSIONS_COMPLETE=false
PROXY_COMPLETE=false
TIMEZONE_COMPLETE=false

if [ "$PERMISSIONS_COMPLETE" = "false" ]; then
  echo "[I] Setting permissions on Bitbucket home directory."
  chown -R ${RUN_USER}:${RUN_GROUP}  "${BITBUCKET_HOME}"
  chmod -R u=rwx,go-rwx              "${BITBUCKET_HOME}"
  sed -i 's/^PERMISSIONS_COMPLETE=.*/PERMISSIONS_COMPLETE=true/g' /usr/local/bin/docker-entrypoint
fi

if [ "$PROXY_COMPLETE" = "false" ]; then
  PROPERTIES_FILE="${BITBUCKET_HOME}/shared/bitbucket.properties"
  if [ ! -d "${BITBUCKET_HOME}/shared" ]; then
    mkdir -p "${BITBUCKET_HOME}/shared"
  fi
  if [ ! -f $PROPERTIES_FILE ]; then
    touch $PROPERTIES_FILE
  fi
  sed -i '/^server.proxy-name=.*/d' $PROPERTIES_FILE
  sed -i '/^server.proxy-port=.*/d' $PROPERTIES_FILE
  sed -i '/^server.scheme=.*/d' $PROPERTIES_FILE
  sed -i '/^server.secure=.*/d' $PROPERTIES_FILE
  if [ "$PROXY_HOSTNAME" -a "$PROXY_PORT" -a "$PROXY_SCHEME" ]; then
    echo "[I] Configuring Bitbucket to operate behind a reverse proxy."
    echo "server.proxy-name=$PROXY_HOSTNAME" >> $PROPERTIES_FILE
    echo "server.proxy-port=$PROXY_PORT" >> $PROPERTIES_FILE
    echo "server.scheme=$PROXY_SCHEME" >> $PROPERTIES_FILE
    if [ "$PROXY_SCHEME" = "http" ]; then
      echo "server.secure=false" >> $PROPERTIES_FILE
    elif [ "$PROXY_SCHEME" = "https" ]; then
      echo "server.secure=true" >> $PROPERTIES_FILE
    else
      echo "[E] Invalid option for WEB_PROXY_SCHEME."
      exit 1
    fi
  fi
  sed -i 's/^PROXY_COMPLETE=.*/PROXY_COMPLETE=true/g' /usr/local/bin/docker-entrypoint
fi

if [ "$TIMEZONE_COMPLETE" = "false" ]; then
  if [ "$TIMEZONE" ]; then
    echo "[I] Setting the time zone."
    cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
  fi
  sed -i 's/^TIMEZONE_COMPLETE=.*/TIMEZONE_COMPLETE=true/g' /usr/local/bin/docker-entrypoint
fi

echo "[I] Entrypoint tasks complete. Starting Bitbucket."
exec su-exec ${RUN_USER} "${BITBUCKET_INSTALL}/bin/start-bitbucket.sh" -fg
