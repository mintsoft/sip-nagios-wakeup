#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::SIP;

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<END;
usage: $0 [ options ]  telephone number
Options:
  -R|--registrar host[:port]   SIP registrar
  -S|--send filename           audio file to play
  --username name
  --password pass
END
    exit( @_ ? 1:0 );
}


my ($file,$registrar,$username,$password);

GetOptions(
    'R|registrar=s' => \$registrar,
#    'S|send=s' => \$file,
    'username=s' =>\$username,
    'password=s' =>\$password,
);
my( $to ) = shift;
$to || usage( "You must specify a phone number!" );

my $ua = Net::SIP::Simple->new(
    registrar => $registrar,
    domain => $registrar,
    from => $username,
    auth => [ $username,$password ],
);

$ua->register( expires => 60 ) || die ( "Registration failed" . $ua->error );

my $rtp_done = 1;
my $call = $ua->invite(
    $to,
    asymetric_rtp => 0,
    rtp_param => [ 8, 160, 160/8000, 'PCMA/8000' ],
) || die "Invitation failed: " . $ua->error;

$ua->loop( 5, \$rtp_done );
$call->bye;