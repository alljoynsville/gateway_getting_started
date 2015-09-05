#!/bin/bash

TARGET_CPU=x86_64

# Getting Started
# So you'd like to get started using the Gateway Agent? You have come to the right place! Be ready to get your hands dirty (well, metaphorically speaking) because we're going to build it from the source.


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


