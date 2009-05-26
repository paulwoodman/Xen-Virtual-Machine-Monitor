#!/usr/bin/perl

$host = "172.25.2.245";

use Net::Ping;

$p = Net::Ping->new( ) or die "Can't create new ping object: $!\n";
print "$host is alive" if $p->ping($host);
$p->close;

exit 0;
