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
    auth => [$username, $password]
);

$ua->register(expires => 10) || die "Registration failed: " . dump($ua->error);

my $call = $ua->invite(
    $to,
    asymetric_rtp => 0,
    rtp_param => [8, 160, 160/8000, 'PCMA/8000'],
);
die "Invitation failed: " . dump($ua->error) unless $call;

my $rejectedCall = defined $call->{'last_error'};

$call->bye;

exit 1 if $rejectedCall;
exit 0;