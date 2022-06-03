#!/bin/bash

cd `dirname $1`
FILE=`pwd`/`basename $1`

pool_operation.sh start ${FILE}
