#!/bin/bash

# Getting Started
# So you'd like to get started using the Gateway Agent? You have come to the right place! Be ready to get your hands dirty (well, metaphorically speaking) because we're going to build it from the source.

TARGET_CPU=x86_64


## Build tools and libs
apt-get update
apt-get -y install build-essential libgtk2.0-dev libssl-dev xsltproc libxml2-dev libcap-dev gcc g++

#To create a 32-bit build of the AllJoyn® framework on a 64-bit operating system, install these required development libraries:
#apt-get -y install gcc-4.8-multilib g++-4.8-multilib libc6-i386 libc6-dev-i386 libssl-dev:i386 libxml2-dev:i386
#You'll also need the ia32 library, which is not available on newer Ubuntu systems (13 and up). Use this workaround to install it:
#cd /etc/apt/sources.list.d
#echo "deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse" >ia32-libs-raring.list
#apt-get update
#apt-get -y install ia32-libs
#rm /etc/apt/sources.list.d/ia32-libs-raring.list
#apt-get update

# Python
#Python should already be installed on Ubuntu. Check to make sure:
#
#python --version
#If you get a version number, ensure that it's 2.6/2.7. Python v3.0 is not compatible and will cause errors. If you get an error, you need to install Python:
#
#apt-get -y install python

#SCons is a software construction tool used to build the AllJoyn framework. SCons is a default package on most Linux distributions.
apt-get -y install scons

#Git is a source code repository access tool. The AllJoyn source code is stored in a set of git projects.
apt-get -y install git-core


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


#Installing a Connector
#Now it's time to install the Connector sample. The installPackage.sh script can be used to install any Connector app as long as it is set up as a tarball (.tar.gz file) in the proper format.

mkdir $AJ_ROOT/staging
cd $AJ_ROOT/staging
cp $AJ_ROOT/gateway/gwagent/cpp/GatewayMgmtApp/installPackage.sh .

#The installPackage.sh script has minor bugs at this point. Run this command to fix them:

sed -i -e 's/mkdir "$tmpDir" || exit 7/mkdir -p "$tmpDir" || exit 7/' -e 's/id -u "$connectorId" &> \/dev\/null/id -u "$connectorId" 2> \/dev\/null/' -e 's/if \[ $? == 0 \]/if \[ $? -eq 0 \]/' -e 's/if \[ $? != 0 \]/if \[ $? -ne 0 \]/' installPackage.sh

#Now, execute the install script:
chmod +x installPackage.sh
tar czf dummyApp1.tar.gz -C $AJ_ROOT/gateway/gwagent/build/linux/$TARGET_CPU/debug/dist/gatewayConnector/tar .
./installPackage.sh dummyApp1.tar.gz

#Copy the apps directory into the daemon directory:
cp -r /opt/alljoyn/apps /opt/alljoyn/alljoyn-daemon.d


#Starting the Connector

# bash -x /etc/init.d/alljoyn-gwagent start
# service alljoyn-gwagent start
#You should now be able to properly see both the Gateway Agent and the dummyApp1 Connector app in the Gateway Controller Sample Android app. If you don't currently have it just keep going and we'll get to it below.

#Creating an ACL
cat <<'EOF' > ~/all.acl
<?xml version="1.0"?>
<!--Copyright (c) 2014, AllSeen Alliance. All rights reserved.

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.
   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.-->
<Acl xmlns="http://www.alljoyn.org/gateway/acl/sample">
  <name>all</name>
  <status>1</status>
  <exposedServices>
    <object>
      <path>/emergency</path>
      <isPrefix>false</isPrefix>
      <interfaces>
        <interface>org.alljoyn.Notification</interface>
      </interfaces>
    </object>
    <object>
      <path>/warning</path>
      <isPrefix>false</isPrefix>
      <interfaces>
        <interface>org.alljoyn.Notification</interface>
      </interfaces>
    </object>
  </exposedServices>
  <remotedApps/>
  <customMetadata/>
</Acl>
EOF
cp ~/all.acl /opt/alljoyn/apps/dummyapp1/acls/all


# bash -x /etc/init.d/alljoyn-gwagent restart
# service alljoyn-gwagent restart

