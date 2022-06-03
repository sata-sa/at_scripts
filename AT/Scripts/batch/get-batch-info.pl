#!/usr/bin/perl

use warnings;
use strict;
use threads;

use DBI;
use utf8;
use DateTime;
use MIME::Base64;
use Term::ANSIColor;
use Scalar::MoreUtils qw(empty);

my $env;
my $dbr;
my $dbh;
my $dbpassfile ;
my $dbuser = "batch";
my $dbhost = "localhost";
my $dbpass = "WdpP2W0Nah";
my $database;
my $query;
my $operation;
my $table;
my $field;
my @row;


##################
# Function usage #
##################
sub usage
{
  print "Usage: $0 {prd/qua/dev} [OPTION]\n\n Options\n\n";
  print "  -a  --areas       : List all Areas.\n";
  print "  -b  --batchs      : List all Batchs.\n";
  print "  -bd --batchs-desc : List all Batchs and all information associated.\n";
  print "  -d  --devteam     : List all Devteams.\n";
  print "  -i  --info        : List all Batchs with info spaced.\n";
  print "  -m  --machines    : List all Machines.\n";
  print "  -n  --nucleos     : List all Nucleos.\n";
  print "\n";
  exit 0;
}


##################
# Function usage #
##################

sub list_generic
{
  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  $query= $dbh->prepare("SELECT $field FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while (@row = $query->fetchrow())
    {
      print "$row[0]\n";
    }
  }

  $query->finish();
  $dbh->disconnect;

}


sub list_batchs_desc
{
  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while (@row = $query->fetchrow())
    {
      print "Nome:$row[1] Path:$row[2] Machine:$row[3] Area:$row[4] Nucleo:$row[5] Retencao_LOGS:$row[6]Meses Devteam:$row[7] \n";
    }
  }

  $query->finish();
  $dbh->disconnect;

}


sub list_info_space
{
  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while (@row = $query->fetchrow())
    {
      print "$row[1] $row[2] $row[3] $row[4] $row[5] $row[6] $row[7]\n"; 
    }
  }

  $query->finish();
  $dbh->disconnect;

}



########################
# Main execution block #
########################
if ($#ARGV == 1)
{
  $env = $ARGV[0];
  $operation = $ARGV[1];

  if (($env ne "prd") and ($env ne "qua") and ($env ne "dev"))
  {
    print "Must define environment (prd/qua/dev)\n";
    usage;
  }
  else
  {
    $database = "Batch_" . uc($env);
  }

  if (($operation eq "-a") or ($operation eq "--areas"))
  {
    $table = "Areas";
    $field = "Areas";
    list_generic;
  }

  if (($operation eq "-b") or ($operation eq "--batchs"))
  {
    $table = "Batch";
    $field = "Name";
    list_generic;
  }

  if (($operation eq "-bd") or ($operation eq "--batchs-desc"))
  {
    $table = "Batch";
    list_batchs_desc; 
  }

  if (($operation eq "-i") or ($operation eq "--info"))
  {
    $table = "Batch";
    list_info_space;
  }

  if (($operation eq "-d") or ($operation eq "--devteam"))
  {
    $table = "Devteam";
    $field = "Devteam";
    list_generic;
  }

  if (($operation eq "-m") or ($operation eq "--machines"))
  {
    $table = "Machines";
    $field = "Machine";
    list_generic;
  }

  if (($operation eq "-n") or ($operation eq "--nucleos"))
  {
    $table = "Nucleos";
    $field = "Nucleos";
    list_generic;
  }

}
else
{
  usage;
}
