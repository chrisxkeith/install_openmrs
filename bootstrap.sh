#! /bin/bash

# DANGER !
# This script deletes your current local repo
# and local openmrs app, e.g., ~/openmrs
# in an attempt to start with a clean slate.

# Assumes:
# - You have forked https://github.com/openmrs/openmrs-core.
# - You have installed maven.
# - You have installed and plan to use Docker.
# - You are running this script from the parent directory of your (to-be-created) local repo.
# - Your github username is in a shell variable called $GITHUB_USERNAME.
# - You are willing to wait (at least) a few minutes.

set -x
if [ -z "$GITHUB_USERNAME" ] ; then
	echo "Please set the GITHUB_USERNAME environment variable to your github username."
	echo "Example: export GITHUB_USERNAME=chrisxkeith"
	exit -665
fi
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
if [ -d "~/openmrs" ] ; then
	rm -rf ~/openmrs
	if [ $? -ne 0 ] ; then
		echo "Failed to delete ~/openmrs"
		exit -669
	fi	
fi
if [ -d "openmrs-core" ] ; then
	rm -rf openmrs-core
	if [ $? -ne 0 ] ; then
		echo "Failed to delete local repo."
		exit -670
	fi	
fi
git clone https://github.com/${GITHUB_USERNAME}/openmrs-core.git
if [ $? -ne 0 ] ; then
	echo "Failed to clone repo."
	exit -671
fi
cd openmrs-core
