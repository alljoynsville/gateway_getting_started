#!/bin/bash

TARGET_CPU=x86_64

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

