#! /bin/bash

# DANGER ! This script deletes your current local repo and local openmrs app(s)
# in an attempt to start with a clean slate.
# Assumes:
# - You have forked ...
# - You have installed maven
# - You have installed and plan to use Docker

set -x
mvn --version
if [ $? -ne 0 ] ; then
	echo "No maven install detected."
	exit -666
fi
docker --version
if [ $? -ne 0 ] ; then
	echo "No docker install detected."
	exit -667
fi
dockerVersion=`docker --version`
v=`echo "$dockerVersion" | sed -E 's/Docker version ([0-9][0-9]).*/\1/'`
if [ $v -gt 27 ] ; then
  echo "Needs docker 27, not $v"
  exit -668
fi
