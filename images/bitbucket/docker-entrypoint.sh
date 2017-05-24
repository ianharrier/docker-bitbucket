#!/bin/sh
set -e

# This script modifies itself after successfully preforming tasks, preventing
# the tasks from running every time the container is restarted.
PERMISSIONS_COMPLETE=false
TIMEZONE_COMPLETE=false

if [ "$PERMISSIONS_COMPLETE" = "false" ]; then
  echo "[I] Setting permissions on Bitbucket home directory."
  chown -R ${RUN_USER}:${RUN_GROUP}  "${BITBUCKET_HOME}"
  chmod -R u=rwx,go-rwx              "${BITBUCKET_HOME}"
  sed -i 's/^PERMISSIONS_COMPLETE=.*/PERMISSIONS_COMPLETE=true/g' /usr/local/bin/docker-entrypoint
fi

if [ "$TIMEZONE_COMPLETE" = "false" ]; then
  if [ "$TIMEZONE" ]; then
    echo "[I] Setting the time zone."
    cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" > /etc/timezone
  fi
  sed -i 's/^TIMEZONE_COMPLETE=.*/TIMEZONE_COMPLETE=true/g' /usr/local/bin/docker-entrypoint
fi

if [ "$PROXY_HOSTNAME" -a "$PROXY_PORT" -a "$PROXY_SCHEME" ]; then
  echo "[I] Configuring Catalina to operate behind a reverse proxy."
  : ${CATALINA_OPTS:=}
  CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyName=${PROXY_HOSTNAME}"
  CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyPort=${PROXY_PORT}"
  CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorScheme=${PROXY_SCHEME}"
  if [ "$PROXY_SCHEME" = "http" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=false"
  elif [ "$PROXY_SCHEME" = "https" ]; then
    CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=true"
  else
    echo "[E] Invalid option for WEB_PROXY_SCHEME."
    exit 1
  fi
fi

echo "[I] Entrypoint tasks complete. Starting Bitbucket."
exec su-exec ${RUN_USER} "${BITBUCKET_INSTALL}/bin/start-bitbucket.sh" -fg
