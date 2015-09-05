#!/bin/bash

TARGET_CPU=x86_64
AJ_ROOT=/root/alljoyn

#alljoyn-daemon
#You'll need to build the alljoyn-daemon from source first.

cd /root/
export AJ_ROOT=`pwd`/alljoyn
mkdir -p $AJ_ROOT/core
cd $AJ_ROOT/core
git clone https://git.allseenalliance.org/gerrit/core/alljoyn.git
cd alljoyn
git checkout v14.12

#Building the Daemon

cd $AJ_ROOT/core/alljoyn
scons BINDINGS=cpp OS=linux CPU=$TARGET_CPU VARIANT=debug BUILD_SERVICES_SAMPLES=off POLICYDB=on WS=off

#Installing the Daemon
mkdir -p /opt/alljoyn/alljoyn-daemon.d
cp $AJ_ROOT/core/alljoyn/build/linux/$TARGET_CPU/debug/dist/cpp/bin/alljoyn-daemon /usr/bin/

#Copy the alljoyn library files to /usr/lib:
find $AJ_ROOT/core/alljoyn/build -name "*\.so" -exec cp {} /usr/lib/ \;

#Create a configuration file:
cat <<'EOF' > ~/config.xml
<busconfig>

    <!--  Our well-known bus type, do not change this  -->
    <type>alljoyn</type>

    <property name="router_advertisement_prefix">org.alljoyn.BusNode</property>

    <!-- Only listen on a local socket. (abstract=/path/to/socket
       means use abstract namespace, don't really create filesystem
       file; only Linux supports this. Use path=/whatever on other
       systems.)  -->
    <listen>unix:abstract=alljoyn</listen>
    <listen>tcp:r4addr=0.0.0.0,r4port=0</listen>

    <limit name="auth_timeout">5000</limit>
    <limit name="max_incomplete_connections">16</limit>
    <limit name="max_completed_connections">100</limit>
    <limit name="max_untrusted_clients">100</limit>
    <flag name="restrict_untrusted_clients">false</flag>

    <ip_name_service>
        <property interfaces="*"/>
        <property disable_directed_broadcast="false"/>
        <property enable_ipv4="true"/>
        <property enable_ipv6="true"/>
    </ip_name_service>
</busconfig>
EOF
cp ~/config.xml /opt/alljoyn/alljoyn-daemon.d/config.xml


#Create an init.d script:
cat <<'EOF' > ~/alljoyn.init
#!/bin/sh
### BEGIN INIT INFO
# Provides: alljoyn-daemon
# Required-Start: $local_fs $network $named $time $syslog
# Required-Stop: $local_fs $network $named $time $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Provides the standalone AllJoyn bus.
### END INIT INFO

SCRIPT=alljoyn-daemon
RUNAS=root
NAME=alljoyn
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/$NAME.log

start() {
  if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
    echo 'Service already running' >&2
    return 1
  fi
  echo 'Starting service…' >&2
  local CMD="$SCRIPT --config-file=/opt/alljoyn/alljoyn-daemon.d/config.xml &> \"$LOGFILE\" & echo \$!"
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
chmod a+x ~/alljoyn.init
cp ~/alljoyn.init /etc/init.d/alljoyn

#Running the daemon

## BUG ## service alljoyn start
# bash -x /etc/init.d/alljoyn start
# To check that the daemon is running:
# bash -x /etc/init.d/alljoyn status
# To stop the daemon:
# bash -x /etc/init.d/alljoyn stop

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

