#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use utf8;
use DateTime;
use MIME::Base64;
use Term::ANSIColor;
use Scalar::MoreUtils qw(empty);

my $env = "NULL";
my $operation = "NULL";
my $objdesc = "NULL";
my $dbr;
my $dbh;
my $dbpassfile ;
my $dbuser = "batch";
my $dbhost = "localhost";
my $dbpass= "WdpP2W0Nah";
my $database;
my $query;

########################
# Function declaration #
########################
sub usage
{
  print "Usage: $0 [PRD/QUA/DEV] [OPERATION] [OBJECT DESCRIPTOR]\n\n Operation\n";
  print "\n -i, --insert\n\n";
  print "  Area              : a,area\n";
  print "  Batch             : b,name,path,machine,area,area,nucleo,log_retention_months\n";
  print "  Devteam           : d,devteam\n";
  print "  Machine           : m,machine\n";
  print "  Nucleo            : n,nucleo\n";
  print "\n -u, --update\n\n";
  print "  Area              : a,name,old value,new value\n";
  print "  Batch             : b,name,old value,new value\n";
  print "  Devteam           : d,name,old value,new value\n";
  print "  Machine           : m,name,old value,new value\n";
  print "  Nucleo            : n,name,old value,new value\n";
  print "\n -d, --delete\n\n";
  print "  Area              : a,name\n";
  print "  Batch             : b,name\n";
  print "  Devteam           : d,name\n";
  print "  Machine           : m,name\n";
  print "  Nucleo            : n,name\n";
  print "\n";
  exit;
}

#################################
# Insert new object in database #
#################################
sub insert_wls_object
{
  my @aobject = split(',',$_[0]);
  my $field;
  my @row;



  # Insert a new Area
  if ($aobject[0] eq "a")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Areas \(Areas\) VALUES \(\"$aobject[1]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Areas WHERE Areas = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Domain id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }


  # Insert a new Batch
  if ($aobject[0] eq "b")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Batch \(Name, Path, Machine, Area, Nucleo, LogsRetention, Devteam\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\", \"$aobject[4]\", \"$aobject[5]\", \"$aobject[6]\", \"$aobject[7]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Batch WHERE Name = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Domain id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }


  # Insert a new Devteam
  if ($aobject[0] eq "d")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Devteam \(Devteam\) VALUES \(\"$aobject[1]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Devteam WHERE Devteam = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Devteam id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }


  # Insert a new Machine
  if ($aobject[0] eq "m")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Machines \(Machine\) VALUES \(\"$aobject[1]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Machines WHERE Machine = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Machine id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }

  # Insert a new Nucleo
  if ($aobject[0] eq "n")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Nucleos \(Nucleos\) VALUES \(\"$aobject[1]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Nucleos WHERE Nucleos = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Machine id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }




}

###############################
# Delete object from database #
###############################
sub delete_wls_object
{
  my @aobject = split(',',$_[0]);
  my $column;
  my $table;

  $aobject[0] = lc($aobject[0]);

  if ($aobject[0] eq "a")
  {
    $table = "Areas";
    $column = "Areas";
  }
  elsif ($aobject[0] eq "b")
  {
    $table = "Batch";
    $column = "Name";
  }
  elsif ($aobject[0] eq "d")
  {
    $table = "Devteam";
    $column = "Devteam";
  }
  elsif ($aobject[0] eq "m")
  {
    $table = "Machines";
    $column = "Machine";
  }
  elsif ($aobject[0] eq "n")
  {
    $table = "Nucleos";
    $column = "Nucleos";
  }
  else
  {
    exit 0;
  }

  $dbr="dbi:mysql:database=$database;host=localhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("DELETE FROM $table WHERE $column =  \"$aobject[1]\"");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;
  $query->finish;
  $dbh->disconnect;
  exit 0;
}

###############################
# Update  object from database #
###############################
sub update_wls_object
{
  my @aobject = split(',',$_[0]);
  my $column;
  my $table;
  my $href;
  my $key;
  my $id;

  $aobject[0] = lc($aobject[0]);

  # Update domain
  if ($aobject[0] eq "a")
  {
    $table = "Areas";
    $column = "Areas";
  }
  elsif ($aobject[0] eq "b")
  {
    $table = "Batch";
    $column = "Name";
  }
  elsif ($aobject[0] eq "d")
  {
    $table = "Devteam";
    $column = "Devteam";
  }
  elsif ($aobject[0] eq "m")
  {
    $table = "Machines";
    $column = "Machine";
  }
  elsif ($aobject[0] eq "n")
  {
    $table = "Nucleos";
    $column = "Nucleos";
  }
  else
  {
    exit 0;
  }

  $dbr="dbi:mysql:database=$database;host=localhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("SELECT * FROM $table WHERE $column = '$aobject[1]'");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      foreach $key (keys %$href)
      {
        if ($href->{$key} eq $aobject[2])
        {
          $column = $key;
          $id = $href->{id};
        }
      }
    }
  }

  if (not empty($id))
  {

    if (empty($aobject[3]))
    {
      $query= $dbh->prepare("UPDATE $table SET $column = '' WHERE id = '$id'");
    }
    else
    {
      $query= $dbh->prepare("UPDATE $table SET $column = '$aobject[3]' WHERE id = '$id'");
    }

    $query->execute() or die "Unable to execute statement: " . $query->errstr;
  }

  $query->finish;
  $dbh->disconnect;
  exit 0;
}

########################
# Main execution block #
########################
if ($#ARGV == 2)
{
  $env = $ARGV[0];
  $operation = $ARGV[1];
  $objdesc = $ARGV[2];

  if (($env ne "prd") and ($env ne "qua") and ($env ne "dev"))
  {
    print "Must define environment (PRD/QUA/DEV)\n";
    usage;
  }
  else
  {
    $database = "Batch_" . uc($env);
  }

  if (($operation eq "-i") or ($operation eq "--insert"))
  {
    insert_wls_object $objdesc;
  }

  if (($operation eq "-u") or ($operation eq "--update"))
  {
    update_wls_object $objdesc;
  }

  if (($operation eq "-d") or ($operation eq "--delete"))
  {
    delete_wls_object $objdesc;
  }
}
else
{
  usage;
}
