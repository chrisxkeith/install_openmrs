#! /bin/bash

# DANGER !
# This script deletes a bunch of stuff, e.g., your current local repo,
# local openmrs app, e.g., ~/openmrs, docker container, etc.,
# in an attempt to start with a clean slate.

# Assumes (some of these assumptions are checked in the script)
# - You have forked https://github.com/openmrs/openmrs-core.
# - You have installed maven.
# - You have installed and plan to use Docker.
# - You have installed Java 21.
# - You are running this script from the parent directory of your (to-be-created) local repo.
# - Your github username is in a shell variable called $GITHUB_USERNAME.
# - You have an input file for the sdk setup for your specific setup, and the path to that file is in a shell variable called $SETUP_INPUT_FILE.
# - You are willing to wait (at least) a few minutes.

set -x

if [ -n "$CONTAINER_NAME" ] ; then
	export CONTAINER_NAME=openmrs-sdk-mysql-v8-4-1
fi

# ------------------------------------------------------------
# Verify environment and tools
if [ -z "$GITHUB_USERNAME" ] ; then
	echo "Please set the GITHUB_USERNAME environment variable to your github username."
	echo "Example: export GITHUB_USERNAME=chrisxkeith"
	exit -663
fi
if [ -z "$MYSQL_ROOT_PASSWORD" ] ; then
	echo "Please set the MYSQL_ROOT_PASSWORD environment variable."
	echo "Example: export MYSQL_ROOT_PASSWORD=<yourRootSqlPassword>"
	exit -663
fi
if [ -z "$SETUP_INPUT_FILE" ] ; then
	echo "Please set the SETUP_INPUT_FILE environment variable to the path of your input file."
	echo "Example: export SETUP_INPUT_FILE=`pwd`/input.txt"
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
containerId=`docker ps -a | grep $CONTAINER_NAME | awk '{print $1}'`
if [ -n "$containerId" ] ; then
	docker stop $containerId
	# Don't care if it was already stopped, so don't check exit code.
	docker rm $containerId
	if [ $? -ne 0 ] ; then
		echo "Failed to delete docker container."
		exit -672
	fi
fi
mvn openmrs-sdk:delete -DserverId=server1

# ------------------------------------------------------------
# Set up repo, mysql docker container and any other one-time setups.
git clone https://github.com/${GITHUB_USERNAME}/openmrs-core.git
if [ $? -ne 0 ] ; then
	echo "Failed to clone repo."
	exit -671
fi
cd openmrs-core
docker container create --name $CONTAINER_NAME --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -p "3306:3306" -v openmrs-data:/var/lib/mysql:z mysql:8.4.1 2>&1 | tee docker-create-output.log
if [ $? -ne 0 ] ; then
	echo "Failed to create mysql docker container."
	exit -672
fi
cat docker-create-output.log | grep -i "Error" > docker-create-error.log
errs=`cat docker-create-error.log | wc -l`
if [ $errs -gt 0 ] ; then
	echo "Error create mysql docker container."
	cat docker-create-error.log
	exit -673
fi
mvn openmrs-sdk:setup < $SETUP_INPUT_FILE 2>&1 | tee setup-sdk-setup-output.log
if [ $? -ne 0 ] ; then
	echo "Failed to setup openmrs-sdk."
	exit -672
fi

# mvn openmrs-sdk:help  2>&1 | tee setup-sdk-help-output.log
# mvn openmrs-sdk:setup < ../install_openmrs/input.txt 2>&1 | tee setup-sdk-input-output.log

# ------------------------------------------------------------
# Run run server, and run tests. Note that the first time you run these commands, they will take a long time as maven downloads dependencies and sets up the sdk. Subsequent runs will be faster.
# docker run -d --name $CONTAINER_NAME 2>&1 | tee docker-run-output.log
# mvn openmrs-sdk:run -DserverId=server1 2>&1 | tee run-server1-output.log
# mvn test 2>&1 | tee test-output.log