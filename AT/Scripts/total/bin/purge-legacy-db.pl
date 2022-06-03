#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use MIME::Base64;
use utf8;
use Scalar::MoreUtils qw(empty);

my $dbpassfile = "/home/weblogic/etc/.wldbpass";
my $dbuser = "weblogic";
my $dbhost = "localhost";
my $database;
my $dbpass;
my $env;
my $query;
my $dbh;
my $dbr;

sub purge_tables
{
  my @row;
  my @tables;
  my $table;

  $query= $dbh->prepare("SHOW TABLES WHERE Tables_in_$database like '%Legacy'");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while (@row = $query->fetchrow())
    {
      push(@tables, $row[0]);
    }
  }
  $query->finish();

  for $table (@tables)
  {
    $query= $dbh->prepare("TRUNCATE TABLE $table");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
  }
  $query->finish();
}

########################
#                      #
# Main execution block #
#                      #
########################
if ($#ARGV > -1)
{
  print "Started\n";
  $env = lc($ARGV[0]);
  $database = "Weblogic_" . uc($env);

  open(FILE, "$dbpassfile") or die $!;

  while (<FILE>)
  {
    chomp;
    $dbpass = $_;
  }

  close(FILE);

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  purge_tables;
}
else
{
  print "Must define environment (PRD/QUA/DEV).\n";
  exit 1;
}
