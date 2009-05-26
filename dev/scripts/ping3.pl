#!/usr/bin/perl

use Net::Ping::External qw(ping);

$host = "172.25.2.245";

# Ping a single host
my $alive = ping(host => $host );
print "$host is online" if $alive;


exit 0;
