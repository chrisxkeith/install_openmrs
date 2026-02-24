#! /bin/bash

set -x
export PATH="`pwd`:$PATH"
export GITHUB_USERNAME=chrisxkeith
export CONTAINER_NAME=openmrs-sdk-mysql-v8-4-1
export SETUP_INPUT_FILE=`pwd`/input.txt

bootstrap.sh
