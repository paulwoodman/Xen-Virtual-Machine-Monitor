#!/usr/bin/perl

$hosts[0] = "172.25.2.245";

use Net::Ping;

$net = Net::Ping->new('syn');
foreach $host (@hosts) {
  $net->ping($host);
}
while (($host, $rtt, $ip) = $net->ack( )) {
  printf "Response from %s (%s) in %d\n", $host, $ip, $rtt;
}

exit 0;
