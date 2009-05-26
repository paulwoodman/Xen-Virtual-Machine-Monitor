#!/usr/bin/perl

$sleepduration = 120; #SET THIS TO DELAY YOU WANT BETWEEN RUNS OF THIS SCRIPT

use Net::Telnet;

use DBI;
use DBD::mysql;

use Time::Local;

$log = "telnet.log";
open(LOG, ">>$log") || die print "$ts no file ${log}\n";

print (LOG "About to go to ts subroutine.\n"); #debug

$ts = &ts();

print (LOG "$ts !!!! STARTING: telnet.pl started on pid $$.\n"); #GET PROCESS ID

# CONFIG VARIABLES FOR DBI
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

while (true) {

$ts = &ts();

##########################################
#
# PREPARE THE QUERY TO GET HOST IP's
$hostsquery = "SELECT ip, live FROM hosts ORDER BY ip";
$hostsquery_handle = $connect->prepare($hostsquery);
#
# EXECUTE THE QUERY
$hostsquery_handle->execute();
#
# BIND TABLE COLUMNS TO VARIABLES
$hostsquery_handle->bind_columns(undef, \$ip, \$live);
#
# LOOP THROUGH RESULTS
while($hostsquery_handle->fetch()) {

if ( $live == 1 ) {

$connection=Net::Telnet->new(Timeout => 5, Host => "$ip", port=>22, Errmode => sub {&error($ip, 0);});
#$lets_see = `netstat -a|grep "$ip"`;
#print (LOG "######## $ts ########\n");
#print (LOG "$lets_see\n");

if ($connection) {
print (LOG "$ts Closing ${ip}.\n");
$connection->close;
} #if ($connection)

} elsif ( $live == 0 ) {

$connection=Net::Telnet->new(Timeout => 5, Host => "$ip", port=>22, Errmode => 'return');

if ($connection) { 
print (LOG "$ts Changing live value from 0 to 1 for ${ip}.\n"); 
&error($ip, 1);
$connection->close; 
} #if ($connection)

} else {

#WE COULD DO AN UPDATE HERE TO CHANGE THE LIVE VALUE TO 1 OR 0
print (LOG "$ts Live value of $live is invalid for ${ip}.\n"); 

} #if ( $live == 1 )

} #while($hostsquery_handle->fetch())

#$hostsquery = $hostsquery_handle->disconnect;

#sleep $sleepduration;
system("sleep $sleepduration");

} #while (true)

exit 0;
##########################################
sub ts {

print (LOG "Got to ts subroutine.\n"); #debug

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t = 0; $t <= 4; $t++ ) { $ts[$t] = &zeropad($ts[$t]); }
$timestamp = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0]";

print (LOG "$ts Timestamp in ts subroutine $timestamp.\n"); #debug

return $timestamp;

}
##########################################
sub error {

$errorip = $_[0];
$errorlive = $_[1];

if ( $errorlive == 0 ) { print (LOG "$ts $errorip connection failed!\n"); }

$hostsupdate = "UPDATE `hosts` SET `live` = '$errorlive' WHERE `hosts`.`ip` = '$errorip'";
$hostsupdate_handle = $connect->prepare($hostsupdate);
$hostsupdate_handle->execute();
#$hostsupdate = $hostsupdate_handle->disconnect;

} 
#####################################
sub zeropad {

$timeelem = $_[0];
if ( $timeelem <= 9 ) { $timeelem = "0${timeelem}"; }
return $timeelem;

}
#####################################

