#!/usr/bin/perl

$sleepduration = 4; #SET THIS TO DELAY YOU WANT BETWEEN RUNS OF THIS SCRIPT

use DBI;
use DBD::mysql;

#Get timestamp for log entries.
use Time::Local;

$ts = &ts();

$log = "/var/www/iexra.iex.com/public/scripts/vm.log"; #output is logged to this file
open(LOG, ">>$log") || die print "no file ${log}\n";

print (LOG "$ts !!!! STARTING: vm.pl started on pid $$.\n"); #GET PROCESS ID

# CONFIG VARIABLES FOR DB
$platform = "mysql";
$database = "xendb_production";
$host = "localhost";
$port = "3306";
$hoststable = "hosts";
$machinestable = "machines";
$user = "root";
$pw = "Assimilated";

# DATA SOURCE NAME
$dsn = "dbi:mysql:$database:localhost:3306";

# PERL DBI CONNECT
$connect = DBI->connect($dsn, $user, $pw);

while (true) {

@hostsips = (); 
@vmlist = ();
@templatelist = ();
@tempextinfo = ();
@extinfo = ();
@uuid = ();
@name = ();
@state = ();
@used = ();
@ei = ();
@eihostip = ();
@eivmuuid = ();
@eivmmem = ();
@eivmip = ();
@eivmfreemem = ();
@eivncport = ();
@templateuuid = ();
@templatename = ();


$ts = &ts();

#print (LOG "$ts Beginning while true loop again. BBBBBBBBBBBBBBBBBBBBBBBBBB\n");


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
@templatelist = `ssh root\@$hostsips[0] xe template-list`;
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

if ( $vmlist[$v] =~ /^[ ]*uuid / ) { $uuid[$i] = &parseline($vmlist[$v]); print (LOG "uuid $uuid[$i] i $i\n"); last SWITCH; }
if ( $vmlist[$v] =~ /^[ ]*name-label / ) { $name[$i] = &parseline($vmlist[$v]); print (LOG "name $name[$i] i $i\n"); last SWITCH; }
if ( $vmlist[$v] =~ /^[ ]*power-state / ) { 
$state[$i] = &parseline($vmlist[$v]); 

#print (LOG "state $state[$i] i $i\n"); #debug
#print (LOG "$ts We just got the state $state[$i] for name $name[i].\n");

if ( $state[$i] =~ /running/ ) { 
@ei = &get_ei($uuid[$i], $name[$i], $state[$i]); 
$eihostip[$i] = $ei[0];
$eivmuuid[$i] = $ei[1];
$eivmmem[$i] = $ei[2];
#print (LOG "if state is running - ip not set yet: name $name[$i] eivmip H${eivmip[$i]}H\n"); #debug
$eivmip[$i] = $ei[3];
$eivmfreemem[$i] = $ei[4];
$eivncport[$i] = $ei[5];

} elsif ( $state[$i] =~ /halted/ ) {

#print (LOG "$ts State is H$state[$i]H running used subroutine.\n");
$used[$i] = &used($uuid[$i]);
#print (LOG "$ts Back from used subroutine, used is H$used[$i]H.\n");

} #if ( $state[$i] =~ /running/ )
$i++; 
last SWITCH; 
} #if ( $vmlist[$v] =~ /^[ ]*power-state / )

} #SWITCH

} #for ( $v = 0; $v <= $#vmlist; $v++ )

#THIS PART PROCESSES THE TEMPLATE LIST 
$o = 0; 
for ( $w = 0; $w <= $#templatelist; $w++ ) { 

SWITCH: { if ( $templatelist[$w] =~ /^[ ]*uuid / ) { $tempuuid = &parseline($templatelist[$w]); chomp $tempuuid; last SWITCH; } 
if ( $templatelist[$w] =~ /^[ ]*name-label / ) {
$tempname = &parseline($templatelist[$w]);
chomp $tempname;

if ( $tempname =~ /Template-/ ) {
$templateuuid[$o] = $tempuuid;
$templatename[$o] = $tempname;
$o++
} #if ( $tempname =~ /Template-/ )

last SWITCH;
} #if ( $templatelist[$v] =~ /^[ ]*name-label / )

} #SWITCH:

} #for ( $w = 0; $w <= $#templatelist; $w++ )
#END PROCESSING THE TEMPLATE LIST 

for ( $x = 0; $x < $i; $x++ ) {

if ( $name[$x] !~ /xshost[0-9][0-9]/ && $name[$x] !~ /IEXRA/ ) { 


#BEGINNING OF THE DB UPDATE FOR VMLIST.

if ( $state[$x] =~ /running/ ) {

#print (LOG "$ts State is running.\n"); #debug
#print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n"); #debug

$machinesupdate = "UPDATE `machines` SET `uuid` = '$uuid[$x]', `ip` = '$eivmip[$x]', `ram` = '$eivmmem[$x]', `state` = '1', `hostuuid` = '$eihostip[$x]', `vncport` = '$eivncport[$x]', `freemem` = '$eivmfreemem[$x]' WHERE `machines`.`name` = '$name[$x]'";
$machinesupdate_handle = $connect->prepare($machinesupdate);
$machinesupdate_handle->execute();
#$machinesupdate = $machinesupdate_handle->disconnect;

} elsif ( $state[$x] =~ /halted/ && $used[$x] == 0 ) {

#print (LOG "$ts State is halted and used is 0.\n"); #debug
#print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] used $used[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n"); #debug

$machinesupdate = "UPDATE `machines` SET `uuid` = '', `ip` = '', `ram` = '', `state` = '', `hostuuid` = '', `vncport` = '', `starttime` = '', `username` = '', `used` = '1', `freemem` = '' WHERE `machines`.`uuid` = '$uuid[$x]'";
$machinesupdate_handle = $connect->prepare($machinesupdate);
$machinesupdate_handle->execute();
#$machinesupdate = $machinesupdate_handle->disconnect;

`ssh root\@$hostsips[0] xe vm-uninstall force="true" vm="$uuid[$x]"`;

#$uuid[$x] = '';
#$eihostip[$x] = '';
#$eivmuuid[$x] = '';
#$eivmmem[$x] = '';
#$eivmip[$x] = '';
#$eivncport[$x] = '';

#print (LOG "EI should be clear now.  $ts uuid $uuid[$x] name $name[$x] state $state[$x] used $used[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n"); #debug

} elsif ( $state[$x] =~ /halted/ && $used[$x] == 1 ) {

#print (LOG "$ts State is halted and used is 1.\n"); #debug
#print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] used $used[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n"); #debug

$machinesupdate = "UPDATE `machines` SET `state` = '0', `vncport` = '0' WHERE `machines`.`uuid` = '$uuid[$x]'";  #NEW UPDATE
$machinesupdate_handle = $connect->prepare($machinesupdate);
$machinesupdate_handle->execute();
#$machinesupdate = $machinesupdate_handle->disconnect;

} else {

#print (LOG "$ts State is not running and if used is 0 then state is not halted either or if state is halted then used is not 0.\n"); #debug
#print (LOG "$ts uuid $uuid[$x] name $name[$x] state $state[$x] used $used[$x] eihostip $eihostip[$x] eivmuuid $eivmuuid[$x] eivmmem $eivmmem[$x] eivmip $eivmip[$x] eivncport $eivncport[$x]\n"); #debug

#$machinesupdate = "UPDATE `machines` SET `uuid` = '$uuid[$x]', `name` = '$name[$x]', `state` = '$state[$x]', `used` = '$used[$x]' WHERE `machines`.`uuid` = '$uuid[$x]'";
#$machinesupdate_handle = $connect->prepare($machinesupdate);
#$machinesupdate_handle->execute();
#$machinesupdate = $machinesupdate_handle->disconnect;

} #if ( $state[$x] =~ /running/ )

#END OF THE DB UPDATE FOR VMLIST.


} #if ( $name[$x] !~ /xshost[0-9][0-9]/ && $name[$x] !~ /IEXRA/ )

} #for ( $x = 0; $x <= $end; $x++ )

#BEGINNING OF THE DB UPDATE FOR TEMPLATELIST.

for ( $u = 0; $u <= $#templateuuid; $u++ ) {

#print (LOG "$ts Template: uuid $templateuuid[$u] name $templatename[$u]\n"); #debug

$machinesupdate2 = "UPDATE `machines` SET `uuid` = '$templateuuid[$u]' WHERE `machines`.`name` = '$templatename[$u]'";
$machinesupdate_handle2 = $connect->prepare($machinesupdate2);
$machinesupdate_handle2->execute();

} #for ( $u = 0; $u <= $#templateuuid; $u++ )

#$machinesupdate2 = $machinesupdate_handle2->disconnect;

#END OF THE DB UPDATE FOR TEMPLATELIST.

$ts = &ts();

#print (LOG "$ts Finished while true loop, going to sleep for $sleepduration seconds.\n"); #debug

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
$hostip = '';
$vmuuid = '';
$vmmem = '';
$vmip = '';
$vmfreemem = '';
$vncport = '';

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
#print (LOG "$ts EI: vmfreemem $vmfreemem\n"); #debug
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
sub used {

$useduuid = $_[0];

#print (LOG "$ts used subroutine: useduuid $useduuid\n"); #debug

# PREPARE THE QUERY TO GET USED VALUE

#print (LOG "$ts useduuid $useduuid\n"); #debug
$usedquery = "SELECT used FROM machines WHERE machines.uuid='$useduuid'";
$usedquery_handle = $connect->prepare($usedquery);
#
# EXECUTE THE QUERY
$usedquery_handle->execute();
#
# BIND TABLE COLUMNS TO VARIABLES
$usedquery_handle->bind_columns(undef, \$usedvalue);
#

while($usedquery_handle->fetch()) {
  $usedreturn = $usedvalue;
}

#print (LOG "$ts used subroutine: usedvalue $usedvalue\n"); #debug

return $usedvalue;

#$usedquery = $usedquery_handle->disconnect;

}
#####################################
exit 0;


