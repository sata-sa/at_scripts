#!/bin/bash

#set -x

LIST=`cat ./hosts_name.txt`
for machine in $LIST; do
      echo "Vou fazer ON-on-start do serviço NSCD na maquina $machine"
      ssh $machine 'chkconfig nscd on'
      echo "Fiz ON-on-start do serviço NSCD na maquina $machine"
done

