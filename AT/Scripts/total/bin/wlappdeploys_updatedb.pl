#!/usr/bin/perl -CA
use warnings;
use strict;

use File::Basename;
use DBI;
use utf8;

my $dbuser="wldeploy";
my $dbpasswd="wls2012#";
my $dbserver="sumonitor05.ritta.local";
my $database="weblogic";
my $prd_table="deployments_prd";
my $qua_table="deployments_qua";

my $dbh;
my $dbr="dbi:mysql:database=$database;host=$dbserver";

my $date = $ARGV[0];          # Date of deployment
my $application = $ARGV[1];   # Name of the application being updated
my $file = $ARGV[2];          # Name of the deployed file
my $ipaddr = $ARGV[3];        # IP Address from the machine that started the deployment
my $state = $ARGV[4];         # Was the deployment successfull?
my $env = $ARGV[5];           # Document section - Production/Quality

my $querystr;
my $query;

sub usage_dbupd
{
  print "Usage: ".basename($0)." <Date> <Application Name> <Uploaded File> <Uploading Machine IP Address> <Upload State> <Environment (PRD/QUA)>\n";
}

if ($#ARGV < 5)
{
  usage_dbupd();
  exit 1;
}

if (!($dbh = DBI->connect($dbr, $dbuser, $dbpasswd)))
{
  print "Unable to connect to database $dbr: $!\n";
  die;
}

if (uc($env) eq "PRD")
{
  $querystr="INSERT INTO $prd_table \(date,application,file,ip,successful\) VALUES \(\"$date\", \"$application\", \"$file\", \"$ipaddr\", \"$state\"\)";
}
else
{
  $querystr="INSERT INTO $qua_table \(date,application,file,ip,successful\) VALUES \(\"$date\", \"$application\", \"$file\", \"$ipaddr\", \"$state\"\)";
}

$query=$dbh->prepare($querystr);

print "Updating deployments database\n";

$query->execute();

$dbh->disconnect;

exit 0;

