#! /bin/bash

# DANGER !
# This script deletes your current local repo
# and local openmrs app, e.g., ~/openmrs
# in an attempt to start with a clean slate.

# Assumes (some of these assumptions are checked in the script)
# - You have forked https://github.com/openmrs/openmrs-core.
# - You have installed maven.
# - You have installed and plan to use Docker.
# - You have installed Java 21.
# - You are running this script from the parent directory of your (to-be-created) local repo.
# - Your github username is in a shell variable called $GITHUB_USERNAME.
# - You are willing to wait (at least) a few minutes.

set -x

# ------------------------------------------------------------
# Verify environment and tools
if [ -z "$GITHUB_USERNAME" ] ; then
	echo "Please set the GITHUB_USERNAME environment variable to your github username."
	echo "Example: export GITHUB_USERNAME=chrisxkeith"
	exit -663
fi
java -version
if [ $? -ne 0 ] ; then
	echo "No java install detected."
	exit -664
fi
v=`java -version 2>&1 | sed -E 's/.* version "([0-9]+).*/\1/'`
if [ $v -ne 21 ] ; then
  echo "Needs java 21, not $v"
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

# ------------------------------------------------------------
# Clean out existing repo, app, docker container, etc. Start with a clean slate.
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

# ------------------------------------------------------------
# Set up mysql docker container and any other one-time setup tasks.
cd openmrs-core
docker run --detach --name openmrs-sdk-mysql-v8-4-1 --env MYSQL_ROOT_PASSWORD=yourSql -p "3306:3306" -v openmrs-data:/var/lib/mysql:z mysql:8.4.1 2>&1 | tee docker-run-output.log
if [ $? -ne 0 ] ; then
	echo "Failed to start mysql docker container."
	exit -672
fi
cat docker-run-output.log | grep -i "Error" > docker-run-error.log
errs=`cat docker-run-error.log | wc -l`
if [ $errs -gt 0 ] ; then
	echo "Error starting mysql docker container."
	cat docker-run-error.log
	exit -673
fi
# mvn org.openmrs.maven.plugins:openmrs-sdk-maven-plugin:setup-sdk 2>&1 | tee setup-sdk-output.log
# mvn openmrs-sdk:help  2>&1 | tee setup-sdk-help-output.log
# mvn openmrs-sdk:setup < ../install_openmrs/input.txt 2>&1 | tee setup-sdk-input-output.log

# ------------------------------------------------------------
# Run run server, and run tests. Note that the first time you run these commands, they will take a long time as maven downloads dependencies and sets up the sdk. Subsequent runs will be faster.

# mvn openmrs-sdk:run -DserverId=server1 2>&1 | tee run-server1-output.log
# mvn test 2>&1 | tee test-output.log