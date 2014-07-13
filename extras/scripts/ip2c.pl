#!/usr/bin/env perl

#
#   This is a very simple IP2C server implemented as a CGI script to use with RocketMinsta
#   Usage:
#       http://example.com/ip2c.pl?ip=1.2.3.4
#

require Geo::IPfree;
require CGI;

print CGI->header('text/plain');

my $geo = Geo::IPfree->new;
my $query = CGI->new;

$geo->Faster;
my ($cn) = $geo->LookUp($query->param('ip'));
print(($cn or "--"), " ", $query->param('ip'));
