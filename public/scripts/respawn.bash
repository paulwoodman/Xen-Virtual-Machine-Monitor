#!/bin/bash

#This script is run periodically by cron to make sure the
#ssh.pl, telnet.pl and vm.pl scripts are running.  If one
#of them is not running it starts it up.

me=`ps -fu www-data|grep "respawn\.bash"|grep -v grep|wc -l`

ps -fu www-data|grep "respawn\.bash"|grep -v grep|wc -l

if [[ $me -le 1 ]]
then

for proc in ssh.pl telnet.pl vm.pl
do

p=`ps -fu www-data|grep "${proc}"|grep -v grep`

if [[ -z $p ]]
then
/var/www/iexra.iex.com/public/scripts/${proc} &
fi

done

fi

exit
