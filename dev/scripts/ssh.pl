#!/usr/bin/perl

#This script gets a list of this class of process,
#ssh -N -L iexra.iex.com:15901:localhost:5901 root@172.25.2.245
#and determines which ones are not running that should be running.
#If it finds any that need to be started it runs the ssh.bash
#script to start them.

$log = "/var/www/scripts/ssh.log"; #output is logged to this file

#HERE ARE THE HOSTS IPADDRESSES.  CHANGE THESE IF THE HOSTS' IPADDRESSES CHANGE.  
$hosts[0] = "172.25.2.245"; 
$hosts[1] = "172.25.2.246";
$hosts[2] = "172.25.2.247";

$sleepduration = 120; #SET THIS TO THE DELAY YOU WANT BETWEEN RUNS OF THIS SCRIPT

#while (true) {

#Get timestamp for log entries.
use Time::Local;

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t; $t <= 4; $t++ ) { $ts[$t] = &zeropad($ts[$t]); }
$ts = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0] ";
#end timestamp stuff

open(LOG, ">>$log") || die print "no file ${log}\n"; 

print (LOG "$ts !!!! STARTING: ssh.pl started on pid $$.\n"); #GET PROCESS ID

#This array contains the list of processes running.
@processes = `ps -ef |grep "ssh -N -L iexra.iex.com"|grep -v "grep"`;

foreach $host_ip (@hosts) {

#!!!!NOTE: IF THE IP ADDRESS CHANGES YOU WILL PROBABLY NEED TO CHANGE THIS CODE!!!!
#!!!!NOTE: IF THE IP ADDRESS CHANGES YOU WILL PROBABLY NEED TO CHANGE THIS CODE!!!!
#The number before the 59 in the ssh command
#ssh -N -L iexra.iex.com:15901:localhost:5901 root@172.25.2.245
#happens to be 244 less than last octet of the ip address for each of the hosts.
#That may change if the ip address changes.
###################################################################################
($dummy1, $dummy2, $dummy3, $last_ip_octet) = split /\./, $host_ip;
$i = $last_ip_octet - 244;
###################################################################################
#!!!!END NOTE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

for ( $z = 1; $z <= 20; $z++ ) {

$x = &zeropad($z);

$foundflag = 0;

foreach $process (@processes) {

chomp $process;

#print (LOG "$ts process $process\n"); #debug

if ( $process =~ /ssh -N -L iexra.iex.com:${i}59${x}:localhost:59$x root\@${host_ip}/ ) {

$foundflag = 1;
break;

} #if ( $process =~ /ssh -N -L iexra.iex.com:${i}59${x}:localhost:59$x root\@${host_ip}/ )

} #foreach $process (@processes)

if ( $foundflag == 0 ) {

print (LOG "$ts STARTING: ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root\@${host_ip}\n");
#system("/var/www/scripts/ssh.bash ${i} ${x} ${host_ip}");
system(1, "ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root@${host_ip}");

} else {

print (LOG "$ts FOUND: ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root\@${host_ip}\n");

} #if ( $foundflag == 0 )

} #for ( $i = 1; $i <= 20; $i++ ) {

} #foreach $host_ip (@hosts) {

close (LOG);

#sleep $sleepduration;

#} #while (true)

exit 0;

#####################################
sub zeropad {

$pad = $_[0];
if ( $pad <= 9 ) { $pad = "0${pad}"; }
return $pad;

}
