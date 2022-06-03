#!/bin/bash

ARGNUM=$#
USER=$1
IP_FILE=$2
INPUT_COMMAND=$3

usage(){
echo
echo "USAGE: $0 root/emrmuser IP_address_file \"REMOTE COMMAND TO EXECUTE\""
echo
echo "ex: $0 emrmuser ./machines.txt \"df -h\""
echo
exit 1
}

if [ "$ARGNUM" -ne "3" ];
then
{
usage
}
fi

echo ""
read -sp 'Insert emrmuser user password: ' PASSWORD
echo ""

for IP in $(cat $IP_FILE | awk '{print $2}');
do
        if [ "$USER" == "emrmuser" ];
        then
                echo ""
                echo "Output of command \"$INPUT_COMMAND\" in $IP machine."
                echo ""
                sshpass -p $PASSWORD ssh -t -o StrictHostKeyChecking=no emrmuser@$IP "unset HISTFILE && $INPUT_COMMAND"
        elif [ "$USER" == "root" ];
        then
                echo ""
                echo "Output of command \"$INPUT_COMMAND\" in $IP machine."
                echo ""
                sshpass -p $PASSWORD ssh -t -o StrictHostKeyChecking=no emrmuser@$IP "unset HISTFILE && echo $PASSWORD | exec sudo -S echo '' && sudo -- bash -c '$INPUT_COMMAND' "
        else
                usage
        fi
done