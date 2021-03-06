#!/bin/bash

STARTDATE=$(date)
{
set -x

TYPES="base"

if [[ $1 == desktop ]]; then
  echo "Installation in progress, please wait" > /etc/nologin
  # Install a full desktop (use this on Windows if you haven't installed an X server)
  TYPES="$TYPES desktop"
fi

# Set up system to work with the Met Office Science Repository Service
TYPES="$TYPES mosrs"

# Address issues some hosts experience with networking (specifically, DNS latency)
# See https://github.com/mitchellh/vagrant/issues/1172
if [ ! $(grep single-request-reopen /etc/resolvconf/resolv.conf.d/base) ]; then
  echo "options single-request-reopen" >> /etc/resolvconf/resolv.conf.d/base && resolvconf -u
fi

# Use the WANdisco subversion packages
add-apt-repository 'deb http://opensource.wandisco.com/ubuntu trusty svn18'
wget -q http://opensource.wandisco.com/wandisco-debian.gpg -O- | sudo apt-key add -  

# Get the latest package info and install any updates
apt-get update -y
apt-get upgrade -y

# Use dos2unix in case any files have Windows EOL characters
apt-get install -y dos2unix

for TYPE in $TYPES; do
  dos2unix -n /vagrant/install-$TYPE.sh /tmp/install-$TYPE.sh
  . /tmp/install-$TYPE.sh
  rm /tmp/install-$TYPE.sh
done

# Remove any redundant packages
apt-get autoremove -y

set +x
echo Finished provisioning at $(date) \(started at $STARTDATE\)
echo

if [[ $1 == desktop ]]; then
  echo Shutting down the system.
  echo Please run vagrant up to restart it.
  rm /etc/nologin
  sudo shutdown -h now
else
  echo Please run vagrant ssh to connect.
fi
} |& tee -a /var/log/install.log
