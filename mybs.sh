#! /bin/bash

set -x
export GITHUB_USERNAME=chrisxkeith
export CONTAINER_NAME=openmrs-sdk-mysql-v8-4-1
export SETUP_INPUT_FILE=`pwd`/install_openmrs/input.txt
export MYSQL_ROOT_PASSWORD=yourSql

./install_openmrs/bootstrap.sh
