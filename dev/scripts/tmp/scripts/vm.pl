#!/usr/bin/perl

$sleepduration = 60; #SET THIS TO DELAY YOU WANT BETWEEN RUNS OF THIS SCRIPT

use DBI;
use DBD::mysql;

#Get timestamp for log entries.
use Time::Local;

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t; $t <= 4; $t++ ) { $ts[$t] = zeropad($ts[$t]); }
$ts = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0] ";


$log = "/var/www/scripts/vm.log"; #output is logged to this file
open(LOG, ">>$log") || die print "no file ${log}\n";

print (LOG "$ts !!!! STARTING: vm.pl started on pid $$.\n"); #GET PROCESS ID

# CONFIG VARIABLES FOR DB
$platform = "mysql";
$database = "xsdb";
$host = "localhost";
$port = "3306";
$hoststable = "hosts";
$vmstable = "vms";
$user = "root";
$pw = "Assimilated";

# DATA SOURCE NAME
$dsn = "dbi:mysql:$database:localhost:3306";

# PERL DBI CONNECT
$connect = DBI->connect($dsn, $user, $pw);

while (true) {

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t; $t <= 4; $t++ ) { $ts[$t] = &zeropad($ts[$t]); }
$ts = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0] ";

print (LOG "$ts Beginning while true loop again. BBBBBBBBBBBBBBBBBBBBBBBBBB\n");


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
$a = 0;
while($hostsquery_handle->fetch()) {
$hostsips[$a] = $ip; 
#print (LOG "$ts firsthostsips $hostsips[$a] ip $ip\n");  #debug
$a++;
}
#$hostsquery = $hostsquery_handle->disconnect;
##########################################


#Grab list of VMs and states then Grab extended info on running machines:
if ( $#hostsips > 0 ) {
@vmlist = `ssh root\@$hostsips[0] xe vm-list`;
$a = 0;
$b = 0;
while ( $a <= $#hostsips ) {

#print (LOG "$ts hostsip element, $hostsips[$a], for xenstore-ls\n"); #debug

@tempextinfo = `ssh root\@$hostsips[$a] xenstore-ls`;
$c = 0;

$extinfo[$b] = "hostip $hostsips[$a]";
$b++;
while ( $c <= $#tempextinfo ) {

$extinfo[$b] = $tempextinfo[$c];
#print (LOG "$ts extinfo $extinfo[$b]\n"); #debug
#print (LOG "$ts Indices for final and temp Extended info arrays: final $b temp $c\n"); #debug
$b++;
$c++;

} #while ( $c <= $#tempextinfo )
$a++;
} #while ( $a <= $#hostips )
} else {

print (LOG "$ts No hosts found.\n");
exit 1;

} #if ( $#hostsips > 0 )

$i = 0;

for ( $v = 0; $v <= $#vmlist; $v++ ) {

chomp $vmlist[$v];

#print (LOG "$ts vmlist $vmlist[$v].\n");

$vmlist[$v] =~ s/[ ]+/ /g;

SWITCH: {

if ( $vmlist[$v] =~ /^[ ]*uuid / ) { $uuid[$i] = &parseline($vmlist[$v]); last SWITCH; }
if ( $vmlist[$v] =~ /^[ ]*name-label / ) { $name[$i] = &parseline($vmlist[$v]); last SWITCH; }
if ( $vmlist[$v] =~ /^[ ]*power-state / ) { 
$state[$i] = &parseline($vmlist[$v]); 

#print (LOG "$ts We just got the state $state[$i] for name $name[i].\n");

if ( $state[$i] =~ /running/ ) { 
@ei = &get_ei($uuid[$i], $name[$i], $state[$i]); 
$eihostip[$i] = $ei[0];
$eivmuuid[$i] = $ei[1];
$eivmmem[$i] = $ei[2];
$eivmip[$i] = $ei[3];
$eivmfreemem[$i] = $ei[4];
$eivncport[$i] = $ei[5];

} elsif ( $state[$i] =~ /halted/ ) {

#print (LOG "$ts State is H$state[$i]H running lock subroutine.\n");
$lock[$i] = &lock($uuid[$i]);
#print (LOG "$ts Back from lock subroutine, lock is H$lock[$i]H.\n");

} #if ( $state[$i] =~ /running/ )
$i++; 
last SWITCH; 
} #if ( $vmlist[$v] =~ /^[ ]*power-state / )

} #SWITCH

} #for ( $v = 0; $v <= $vmlistin[$#vmlistin]; $v++ )



for ( $x = 0; $x < $i; $x++ ) {

if ( $name[$x] !~ /xshost[0-9][0-9]/ && $name[$x] !~ /IEXRA/ ) { 


#BEGINNING OF THE DB UPDATE.

if ( $state[$x] =~ /running/ ) {

print (LOG "$ts State is running.\n");
print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n");

$vmsupdate = "UPDATE `vms` SET `uuid` = '$uuid[$x]', `ip` = '$eivmip[$x]', `ram` = '$eivmmem[$x]', `state` = '1', `hostuuid` = '$eihostip[$x]', `vncport` = '$eivncport[$x]', `freemem` = '$eivmfreemem[$x]' WHERE `vms`.`name` = '$name[$x]'";
$vmsupdate_handle = $connect->prepare($vmsupdate);
$vmsupdate_handle->execute();
#$vmsupdate = $vmsupdate_handle->disconnect;

} elsif ( $state[$x] =~ /halted/ && $lock[$x] == 0 ) {

print (LOG "$ts State is halted and lock is 0.\n");
print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] lock $lock[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n");

$vmsupdate = "UPDATE `vms` SET `uuid` = '', `ip` = '', `ram` = '', `state` = '', `hostuuid` = '', `vncport` = '', `starttime` = '', `username` = '', `used` = '1', `freemem` = '' WHERE `vms`.`uuid` = '$uuid[$x]'";
$vmsupdate_handle = $connect->prepare($vmsupdate);
$vmsupdate_handle->execute();
#$vmsupdate = $vmsupdate_handle->disconnect;

`ssh root\@$hostsips[0] xe vm-uninstall force="true" vm="$uuid[$x]"`;

} else {

print (LOG "$ts State is not running and if lock is 0 then state is not halted either or is state is halted then lock is not 0.\n");
print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] lock $lock[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n");

#$vmsupdate = "UPDATE `vms` SET `uuid` = '$uuid[$x]', `name` = '$name[$x]', `state` = '$state[$x]', `used` = '$lock[$x]' WHERE `vms`.`uuid` = '$uuid[$x]'";
#$vmsupdate_handle = $connect->prepare($vmsupdate);
#$vmsupdate_handle->execute();
#$vmsupdate = $vmsupdate_handle->disconnect;

} #if ( $state[$x] =~ /running/ )

#END OF THE DB UPDATE.


} #if ( $name[$x] !~ /xshost[0-9][0-9]/ && $name[$x] !~ /IEXRA/ )

} #for ( $x = 0; $x <= $end; $x++ )

@ts = localtime();
$ts[4]++;
$ts[5] += 1900;
for ( $t; $t <= 4; $t++ ) { $ts[$t] = &zeropad($ts[$t]); }
$ts = "$ts[4]/$ts[3]/$ts[5]/$ts[2]:$ts[1]:$ts[0] ";

print (LOG "$ts Finished while true loop, going to sleep for $sleepduration seconds.\n");

sleep $sleepduration;

} #while (true)

close (LOG);

exit 0;
#####################################
sub zeropad {

$timeelem = $_[0];
if ( $timeelem <= 9 ) { $timeelem = "0${timeelem}"; }
return $timeelem;

}
#####################################
sub parseline {

@vm = split /:/, $_[0]; 
$vm[$#vm] =~ s/^[ ]*//; 
$vm[$#vm] =~ s/[ ]*$//; 

return $vm[$#vm];

}
#####################################
sub get_ei {

$eiuuid = $_[0];
$einame = $_[1];
$eistate = $_[2];
$uuidflag = 0;

foreach $elem (@extinfo) {

chomp $elem;

#print (LOG "$ts Extended info line: H${elem}H\n"); #debug

if ( $elem =~ /^hostip/ ) {
($dummy01, $hostip) = split / /, $elem;  
#print (LOG "$ts EI: hostip $hostip\n"); #debug
} #if ( $elem =~ /^hostip/ )
if ( $elem =~ /vm/ ) { 
$uuidflag = 0;
($dummy01, $dummy02, $vmuuid) = split/\//, $elem; 
$vmuuid =~ s/\"$//;
#print (LOG "$ts EI: Match uuid: vmuuid $vmuuid eiuuid $eiuuid\n"); #debug

if ( $vmuuid =~ $eiuuid ) {

#print (LOG "$ts The EI if vmuuid matches eiuuid statement is true.\n"); #debug
$uuidflag = 1;

} #if ( $vmuuid =~ $eiuuid )

} #if ( $elem =~ /^[ ]*vm =/ )

if ( $elem =~ /target \=/ && $uuidflag == 1 ) {
($dummy01, $vmmem) = split/\"/, $elem;
#print (LOG "$ts EI: vmmem $vmmem\n"); #debug
} #if ( $elem =~ /target \=/ && $uuidflag ==1 )

if ( $elem =~ /ip \=/ && $uuidflag == 1 ) {
($dummy01, $vmip) = split/\"/, $elem;
#print (LOG "$ts EI: vmip $vmip\n"); #debug
} #if ( $elem =~ /ip \=/ && $uuidflag == 1 )

if ( $elem =~ /meminfo_free \=/ && $uuidflag == 1 ) {
($dummy01, $vmfreemem) = split/\"/, $elem;
print (LOG "$ts EI: vmfreemem $vmfreemem\n"); #debug
} #if ( $elem =~ /ip \=/ && $uuidflag == 1 )

#print (LOG "$ts EI: We are about to check for vnc-port.\n"); #debug

if ( $elem =~ /^    vnc-port \=/ && $uuidflag == 1 ) { 

($dummy01, $vncport) = split/\"/, $elem; 

#print (LOG "$ts EI: vncport $vncport\n"); #debug

return $hostip, $vmuuid, $vmmem, $vmip, $vmfreemem, $vncport;

} #if ( $elem =~ /^[ ]*vnc-port =/ )

} #foreach $elem (@extinfo)

}
#####################################
sub lock {

$lockuuid = $_[0];

#print (LOG "$ts lock subroutine: lockuuid $lockuuid\n"); #debug

# PREPARE THE QUERY TO GET LOCK VALUE

#print (LOG "$ts lockuuid $lockuuid\n"); #debug
$lockquery = "SELECT used FROM vms WHERE vms.uuid='$lockuuid'";
$lockquery_handle = $connect->prepare($lockquery);
#
# EXECUTE THE QUERY
$lockquery_handle->execute();
#
# BIND TABLE COLUMNS TO VARIABLES
$lockquery_handle->bind_columns(undef, \$lockvalue);
#

while($lockquery_handle->fetch()) {
  $lockreturn = $lockvalue;
}

#print (LOG "$ts lock subroutine: lockvalue $lockvalue\n"); #debug

return $lockvalue;

#$lockquery = $lockquery_handle->disconnect;

}
#####################################
exit 0;


