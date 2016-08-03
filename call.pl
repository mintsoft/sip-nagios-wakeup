#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default bundling);
use Net::SIP;
#Usage

sub usage {
    print STDERR "ERROR: @_\n" if @_;
    print STDERR <<EOS;
usage: $0 [ options ]  no de tel 
Joue un fichier vers un téléphone après que le correspondant décroche
Options:
  -R|--registrar host[:port]   register at given address
  -S|--send filename           Fichier audio
  --username name              
  --password pass              probablement mieux à faire pour le cacher d'un ps
EOS
    exit( @_ ? 1:0 );
}


my ($file,$registrar,$username,$password);

GetOptions(
    'R|registrar=s' => \$registrar,
    'S|send=s' => \$file,
    'username=s' =>\$username,
    'password=s' =>\$password,
) || usage( "bad option" );
my( $to )=@ARGV;
$to || usage( "pas de destination" );

# create new agent


print "Creating connection\n";
my $ua = Net::SIP::Simple->new(
registrar => $registrar,
domain => $registrar,
from => $username,
auth => [ $username,$password ],

);

# Register agent

$ua->register( expires => 1800 ) # <- Valeur mini chez free

|| die ( "Pas enregistré " . $ua->error );
print "Enregistré\n";
# Variables d'arret.(sort de loop quand rtp_done est vrai)

my $rtp_done;
print "Appelle ".$to.'@'.$registrar."\n";
my $call= $ua->invite( $to,
    init_media => $ua->rtp( 'send_recv', $file ),
    cb_rtp_done => \$rtp_done,
    asymetric_rtp => 0,
    rtp_param => [ 8, 160, 160/8000, 'PCMA/8000' ],

) ||die "invite failed: ".$ua->error;

# Mainloop

$ua->loop( \$rtp_done );
$call->bye;