#!/bin/bash

. ${HOME}/bin/common_env.sh


MACHINESRAW=(`cat tempmachines.txt`)

for machine in ${MACHINESRAW[@]}; do
   OS=`ssh weblogic@$machine uname `
   if [ $OS == "Linux" ]; then
      info $machine
      #ssh weblogic@$machine df -k | grep upload | awk '{print $5}'
      DIR=(`ssh weblogic@$machine df -k | grep upload| awk '{print $5}'`)
      for dirs in ${DIR[@]}; do
         ssh weblogic@$machine tree -d -L 1 $dirs
         continue
      done
   elif [ $OS == "SunOS" ]; then
      info $machine
      #ssh weblogic@$machine df -k | grep upload | awk '{print $6}'
      DIR=(`ssh weblogic@$machine df -k | grep upload | awk '{print $6}'`)
      for dirs in ${DIR[@]}; do
#local onde andei a mexer... SHADOW!!!
         ssh weblogic@$machine find . -type d $dirs
      done
   else
      failure "SHADOW WAS HERE!!!"
      exit 1
   fi
done
