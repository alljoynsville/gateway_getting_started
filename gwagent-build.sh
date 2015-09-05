#!/bin/bash

TARGET_CPU=x86_64

#Building the Gateway Agent

#First pull the remaining pieces of code:
mkdir $AJ_ROOT/services
mkdir $AJ_ROOT/gateway
cd $AJ_ROOT/services
git clone https://git.allseenalliance.org/gerrit/services/base.git
cd base
git checkout v14.12
cd $AJ_ROOT/gateway
git clone https://git.allseenalliance.org/gerrit/gateway/gwagent.git
cd gwagent

#Next build from the gateway/gwagent folder:

cd $AJ_ROOT/gateway/gwagent
scons BINDINGS=cpp OS=linux CPU=$TARGET_CPU VARIANT=debug BUILD_SERVICES_SAMPLES=off POLICYDB=on ALLJOYN_DISTDIR=$AJ_ROOT/core/alljoyn/build/linux/$TARGET_CPU/debug/dist WS=off

# Copy the shared library files to /usr/lib:

#bash -x /etc/init.d/alljoyn stop
find build -name "*\.so" -exec cp {} /usr/lib \;
#service alljoyn start

#Copy the Gateway Management App to /usr/bin:
find build -name "alljoyn-gwagent" -type f -exec cp {} /usr/bin/alljoyn-gwagent \;

#Add the manifest.xsd file to the /opt/alljoyn/gw-mgmt folder:

mkdir /opt/alljoyn/gwagent
cp $AJ_ROOT/gateway/gwagent/cpp/GatewayMgmtApp/manifest.xsd /opt/alljoyn/gwagent/

#Create an init.d script for the Gateway Management App:
cat <<'EOF' > ~/alljoyn-gwagent.init
#!/bin/sh
### BEGIN INIT INFO
# Provides: alljoyn-gwagent
# Required-Start: $local_fs $network $named $time $syslog
# Required-Stop: $local_fs $network $named $time $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Provides the AllJoyn Gateway Agent service.
### END INIT INFO

SCRIPT=alljoyn-gwagent
RUNAS=root
NAME=alljoyn-gwagent
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/$NAME.log

start() {
  if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
    echo 'Service already running' >&2
    return 1
  fi
  echo 'Starting service…' >&2
  local CMD="$SCRIPT &> \"$LOGFILE\" & echo \$!"
  su -c "$CMD" $RUNAS > "$PIDFILE"
  echo 'Service started' >&2
}

stop() {
  if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
    echo 'Service not running' >&2
    return 1
  fi
  echo 'Stopping service…' >&2
  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
  echo 'Service stopped' >&2
}

uninstall() {
  echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
  local SURE
  read SURE
  if [ "$SURE" = "yes" ]; then
    stop
    rm -f "$PIDFILE"
    echo "Notice: log file was not removed: '$LOGFILE'" >&2
    update-rc.d -f <NAME> remove
    rm -fv "$0"
  fi
}

status() {
  printf "%-50s" "Checking $NAME..."
  if [ -f $PIDFILE ]; then
    PID=$(cat $PIDFILE)
    if [ -z "$(ps axf | grep ${PID} | grep -v grep)" ]; then
      printf "%s\n" "The process appears to be dead but pidfile still exists"
    else
      echo "Running, the PID is $PID"
    fi
  else
    printf "%s\n" "Service not running"
  fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  uninstall)
    uninstall
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|uninstall}"
esac
EOF
chmod a+x ~/alljoyn-gwagent.init
cp ~/alljoyn-gwagent.init /etc/init.d/alljoyn-gwagent


