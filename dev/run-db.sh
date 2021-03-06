#!/usr/bin/env bash

SELF=$(cd $(dirname $0) && pwd)
. "$SELF/docker-command.sh"

#set -e
#set -o pipefail

NETWORK="--network mlsql-network"

if [[ "${WITHOUT_NETWORK}" == "true" ]];then
  NETWORK=""
fi



docker ps |grep mlsql-console-mysql
if [[ "$?" != "0" ]];then
  docker run --name mlsql-console-mysql -e MYSQL_ROOT_PASSWORD=mlsql ${NETWORK} -d mysql:5.7
fi


EXEC_MLSQL_PREFIX="exec mysql -uroot -pmlsql --protocol=tcp "

#set +e
check_ready mlsql-console-mysql "${EXEC_MLSQL_PREFIX} -e 'SHOW CHARACTER SET'"

if [[ "$?" != "0" ]];then
   echo "cannot start mysql in docker"
   exit 1
fi
#set -e

#创建数据库
docker_exec mlsql-console-mysql "${EXEC_MLSQL_PREFIX} -e 'create database mlsql_console'"

#导入数据
docker_id=$(docker inspect -f   '{{.Id}}' mlsql-console-mysql)
docker cp ../src/main/resources/db.sql ${docker_id}:/tmp
docker_exec mlsql-console-mysql "${EXEC_MLSQL_PREFIX} mlsql_console < /tmp/db.sql"