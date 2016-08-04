#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::SIP;
use Data::Dump qw(dump);

my ($to, $registrar, $username, $password);

GetOptions(
    'r|registrar=s' => \$registrar,
    'u|username=s' =>\$username,
    'p|password=s' =>\$password,
    't|to=s' => \$to,
);

my $ua = Net::SIP::Simple->new(
    registrar => $registrar,
    domain => $registrar,
    from => $username,
    auth => [$username, $password],
cb_noanswer => sub{  die "BROKEN"; }
);

$ua->register(expires => 10) || die "Registration failed: " . dump($ua->error);

my $failedCall = 1;
my $call = $ua->invite(
    $to,
    asymetric_rtp => 0,
    rtp_param => [8, 160, 160/8000, 'PCMA/8000'],
    ring_time => 10,
);

die "Invitation failed: " . dump($ua->error) unless $call;
$failedCall = 0 if not defined $call->{'last_error'};

$call->bye;    
$ua->cleanup();

exit 1 if $failedCall;
exit 0;
