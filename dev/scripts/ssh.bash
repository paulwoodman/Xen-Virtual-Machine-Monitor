#!/bin/bash

#This script is called by ssh.pl to start the ssh process below if
#ssh.pl determines that it is not running.

ssh -N -L iexra.iex.com:${1}59${2}:localhost:59${2} root@${3} &

exit
