#!/usr/bin/perl

use DBI;
use DBD::mysql;



# CONFIG VARIABLES
$platform = "mysql";
$database = "xsdb";
$host = "localhost";
$port = "3306";
$user = "root";
$pw = "Assimilated";

# DATA SOURCE NAME
$dsn = "dbi:mysql:$database:localhost:3306";

# PERL DBI CONNECT
$connect = DBI->connect($dsn, $user, $pw);


##########################################
#
# PREPARE THE QUERY TO GET HOST IP's

#$templatesupdate = "UPDATE templates SET lock = '1', owner = 'mwspitzer' WHERE id = '1'";
#$templatesupdate = "UPDATE \`xsdb\`.\`templates\` SET \`lock\` = \'1\', \`owner\` = \'mwspitzer\' WHERE \`templates\`.\`id\` = \'1\'";
$templatesupdate = "UPDATE `templates` SET `lock` = '1', `owner` = 'mwspitzer' WHERE `templates`.`id` = '1'";


$tempplateupdate_handle = $connect->prepare($templatesupdate);
# EXECUTE THE QUERY
$tempplateupdate_handle->execute();

$templatesquery = "SELECT * FROM templates WHERE id = '1'";
$tempplatequery_handle = $connect->prepare($templatesquery);
$tempplatequery_handle->execute();
$tempplatequery_handle->bind_columns(undef, \$id, \$name, \$tname, \$lock, \$owner, \$available);
#
# LOOP THROUGH RESULTS
$a = 0;
while($tempplatequery_handle->fetch()) {
print "$id	$name	$tname	$lock	$owner	$available\n";  #debug
$a++;
}


#$templatesupdate = "UPDATE templates SET lock = '0', owner = '' WHERE id = '1'";
#$templatesupdate = "UPDATE \`xsdb\`.\`templates\` SET \`lock\` = \'0\', \`owner\` = \'\' WHERE \`templates\`.\`id\` = \'1\'";
$templatesupdate = "UPDATE `templates` SET `lock` = '0', `owner` = '' WHERE `templates`.`id` = '1'";

$tempplateupdate_handle = $connect->prepare($templatesupdate);

$tempplateupdate_handle->execute();

$tempplatequery_handle = $connect->prepare($templatesquery);
$tempplatequery_handle->execute();
$tempplatequery_handle->bind_columns(undef, \$id, \$name, \$tname, \$lock, \$owner, \$available);
#
# LOOP THROUGH RESULTS
$a = 0;
while($tempplatequery_handle->fetch()) {
print "$id      $name   $tname  $lock   $owner  $available\n";  #debug
$a++;
}

#
#
#I've replaced the variables I use with actual entries, which are between single quotes:
#
#UPDATE `xsdb`.`templates` SET `lock` = '1', `owner` = 'mwspitzer' WHERE `templates`.`id` = '1'
#
#SELECT * FROM templates WHERE id = '1'
#
#UPDATE `xsdb`.`templates` SET `lock` = '0', `owner` = '' WHERE `templates`.`id` = '1'
#
#SELECT * FROM templates WHERE id = '1'


#$hostsquery = $hostsquery_handle->disconnect;

exit 0;
