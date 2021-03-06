#!/usr/bin/perl

use Net::Telnet;

use DBI;
use DBD::mysql;

use Time::Local;


@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t; $t <= 4; $t++ ) { $ts[$t] = zeropad($ts[$t]); }
$ts = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0] ";


#$log = "/var/www/scripts/telnet.log";
$log = "telnet.log";
open(LOG, ">>$log") || die print "no file ${log}\n";

# CONFIG VARIABLES
$platform = "mysql";
$database = "xendb";
$host = "localhost";
$port = "3306";
$hoststable = "hosts";
$user = "root";
$pw = "Assimilated";

# DATA SOURCE NAME
$dsn = "dbi:mysql:$database:localhost:3306";

# PERL DBI CONNECT
$connect = DBI->connect($dsn, $user, $pw);


##########################################
#
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
while($hostsquery_handle->fetch()) {
$connection=Net::Telnet->new(Timeout => 5, Host => "$ip", port=>22, Errmode => sub {&error($ip);});
#$lets_see = `netstat -a|grep "$ip"`;
#print (LOG "######## $ts ########\n");
#print (LOG "$lets_see\n");
$connection->close;  #THIS GETS AN ERROR IF THE CONNECTION FAILS
}
#$hostsquery = $hostsquery_handle->disconnect;



exit 0;
##########################################
sub error {

$errorip = $_[0];

print (LOG "$ts Connection Failed!\n");

$hostsupdate = "UPDATE `hosts` SET `live` = '0' WHERE `hosts`.`ip` = '$errorip'";
$hostsupdate_handle = $connect->prepare($hostsupdate);
$hostsupdate_handle->execute();
#$vmsupdate = $vmsupdate_handle->disconnect;

} 
#####################################
sub zeropad {

$timeelem = $_[0];
if ( $timeelem <= 9 ) { $timeelem = "0${timeelem}"; }
return $timeelem;

}
#####################################

