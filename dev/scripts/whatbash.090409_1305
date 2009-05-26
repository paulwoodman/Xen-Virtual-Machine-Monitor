#!/bin/bash

host[1]="172.25.2.245"
host[2]="172.25.2.246"
host[3]="172.25.2.247"

dir=/var/www/scripts
infile=${dir}/ssh.in
log=${dir}/ssh.log
ps -eo args|grep "ssh -N -L iexra.iex.com:"|grep -v grep|sort -n > $infile

x=0
while read LINE
do

#echo "$LINE"
process[$x]="$LINE" 
((x = $x + 1))

done < $infile

i=1
while [ $i -le 3 ]
do

j=1
while [ $j -le 20 ]
do

foundflag=0

m=$j
if [[ $m -le 9 ]]
then
m="0${m}"
fi

#echo "ssh:		Hssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]}H" #debug

k=0
while [ $k -le $x ]
do
#echo "process[k]:	H${process[$k]}H" #debug
if [[ ${process[$k]} == "ssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]}" ]]
then
echo "`date +"%D %T"` FOUND: ssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]}" >> $log
foundflag=1
break
fi #if [[ ${process[$k]} == "ssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]}" ]]

#echo "foundflag inside $foundflag" >> $log #debug

((k = $k + 1))

done #while [ $k -le $x ]

#echo "foundflag outside $foundflag" >> $log #debug

if [[ $foundflag -eq 0 ]]
then
echo "`date +"%D %T"` STARTING: ssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]}" >> $log
ssh -N -L iexra.iex.com:${i}59${m}:localhost:59${m} root@${host[$i]} &
fi

((j = $j + 1))

done #while [ $j -le 20 ]

((i = $i + 1))

done #while [ $i -le 3 ]


exit 0
