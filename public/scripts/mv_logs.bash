#!/bin/bash

dir="/var/www/iexra.iex.com/log"

for file in xenhostcheckd.log xentunneld.log xenvmmd.log
do

if [[ -f $file ]]
then

b=`basename $file .log`

x=3
while [[ $x -ge 0 ]]
do

((y = $x - 1))

if [[ -f ${dir}/${b}${y}.log ]]
then
mv ${dir}/${b}${y}.log.gz ${dir}/${b}${x}.log.gz
fi

x=$y

done

mv ${dir}/$file ${dir}/${b}0.log
gzip ${dir}/${b}0.log

fi

done

exit

