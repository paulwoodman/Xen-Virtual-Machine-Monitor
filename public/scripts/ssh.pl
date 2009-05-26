#!/usr/bin/perl

#This script gets a list of this class of process,
#ssh -N -L iexra.iex.com:15901:localhost:5901 root@172.25.2.245
#and determines which ones are not running that should be running.
#If it finds any that need to be started it starts them.

$log = "ssh.log"; #output is logged to this file

$sleepduration = 120; #SET THIS TO THE DELAY YOU WANT BETWEEN RUNS OF THIS SCRIPT

use DBI;
use DBD::mysql;

#Get timestamp for log entries.

use Time::Local;
$ts = &ts();

#end timestamp stuff

open(LOG, ">>$log") || die print "no file ${log}\n"; 
print (LOG "$ts !!!! STARTING: ssh.pl started on pid $$.\n"); #GET PROCESS ID

while (true) {

######## GET HOSTS IPADDRESSES FOR HOSTS WHERE LIVE = 1

# CONFIG VARIABLES
$platform = "mysql";
$database = "xendb_dev";
$host = "localhost";
$port = "3306";
$hoststable = "hosts";
$user = "root";
$pw = "Assimilated";

# DATA SOURCE NAME
$dsn = "dbi:mysql:$database:localhost:3306";

# PERL DBI CONNECT
$connect = DBI->connect($dsn, $user, $pw);

# PREPARE THE QUERY TO GET HOST IP's
$hostsquery = "SELECT ip FROM hosts WHERE live=1 ORDER BY ip";
$hostsquery_handle = $connect->prepare($hostsquery);
#
# EXECUTE THE QUERY
$hostsquery_handle->execute();
#
# BIND TABLE COLUMNS TO VARIABLES
$hostsquery_handle->bind_columns(undef, \$ip);
#
# LOOP THROUGH RESULTS

$a = 0;
while($hostsquery_handle->fetch()) {
$hosts[$a] = $ip;
$a++;
} #while($hostsquery_handle->fetch())

######## FINISHED GETTING HOSTS IPADDRESSES

#Get timestamp for log entries.
$ts = &ts();

print (LOG "$ts ##### Checking processes. #####\n"); #Starting while loop again

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

#This starts the process
#system("nohup ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root\@${host_ip} > /dev/null 2>&1 &");
system("ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root\@${host_ip} > /dev/null 2>&1 &");

#} else {

#print (LOG "$ts FOUND: ssh -N -L iexra.iex.com:${i}59${x}:localhost:59${x} root\@${host_ip}\n");

} #if ( $foundflag == 0 )

} #for ( $i = 1; $i <= 20; $i++ ) {

} #foreach $host_ip (@hosts) {

sleep $sleepduration;

} #while (true)

close (LOG);

exit 0;

#####################################
sub ts {

#print (LOG "Got to ts subroutine.\n"); #debug

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t = 0; $t <= 4; $t++ ) { $ts[$t] = &zeropad($ts[$t]); }
$timestamp = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0]";

#print (LOG "$ts Timestamp in ts subroutine $timestamp.\n"); #debug

return $timestamp;

}
#####################################
sub zeropad {

$pad = $_[0];
if ( $pad <= 9 ) { $pad = "0${pad}"; }
return $pad;

}
