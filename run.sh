#!/bin/bash

bash -x /etc/init.d/alljoyn start
bash -x /etc/init.d/alljoyn-gwagent start

tail -f /var/log/alljoyn-gwagent.log

