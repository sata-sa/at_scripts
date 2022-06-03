#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use utf8;
use DateTime;
use MIME::Base64;
use Term::ANSIColor;
use Scalar::MoreUtils qw(empty);

########################
# Variable declaration #
########################
my $env = "NULL";
my $operation = "NULL";
my $objdesc = "NULL";
my $dbr;
my $dbh;
my $dbpassfile = "/home/weblogic/etc/.wldbpass";
my $dbuser = "weblogic";
my $dbhost = "localhost";
my $dbpass;
my $database;
my $query;

########################
# Function declaration #
########################
sub usage
{
  print "Usage: $0 [PRD/QUA/DEV/SANDBOX] [OPERATION] [OBJECT DESCRIPTOR]\n\n Operation\n";
  print "\n -i, --insert\n\n";
  print "  Cluster           : c,name,domain\n";
  print "  Server            : s,name,domain,cluster,machine\n";
  print "  Application       : a,name,virtualhost,target,frontends,hotdeploy,numberofversions,deploydate\n";
  print "  Machine           : m,name\n";
  print "  Domain            : d,name,wls_version,jdk_version,host,port,user,password,location\n";
  print "  Frontend          : f,name,isdefault\n";
  print "  Log rule (insert) : l,domain/application name,relative path,depth,log pattern,retention period,action,bck machine,bck user,bck password,bck path\n";
  print "\n -u, --update\n\n";
  print "  Cluster           : c,name,old value,new value\n";
  print "  Server            : s,name,old value,new value\n";
  print "  Application       : a,name,old value,new value\n";
  print "  Machine           : m,name,old value,new value\n";
  print "  Domain            : d,name,old value,new value\n";
  print "  Frontend          : f,name,old value,new value\n";
  print "  File              : e,name,old value,new value\n";
  print "\n -d, --delete\n\n";
  print "  Cluster           : c,name\n";
  print "  Server            : s,name\n";
  print "  Application       : a,name\n";
  print "  Machine           : m,name\n";
  print "  Domain            : d,name\n";
  print "  Frontend          : f,name\n";
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

  # Insert a new Domain
  if ($aobject[0] eq "d")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Domains \(Domain, WLS_Version, JDK_Version, Host, Port, User, Password, Location\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\", \"$aobject[4]\", \"$aobject[5]\", \"$aobject[6]\", \"$aobject[7]\", \"$aobject[8]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Domains WHERE Domain = \"$aobject[1]\"");
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

  # Insert a new Server
  if ($aobject[0] eq "s")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    if (empty($aobject[4]))
    {
      $query= $dbh->prepare("INSERT INTO Servers \(Server, Domain, Cluster\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\"\)");
    }
    else
    {
      $query= $dbh->prepare("INSERT INTO Servers \(Server, Domain, Cluster, Machine\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\", \"$aobject[4]\"\)");
    }

    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Servers WHERE Server = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Server id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }

  # Insert a new Cluster
  if ($aobject[0] eq "c")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Clusters \(Cluster, Domain\) VALUES \(\"$aobject[1]\", \"$aobject[2]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Clusters WHERE Cluster = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Cluster id: $row[0]\n";
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

  # Insert a new Frontend
  if ($aobject[0] eq "f")
  {
    $aobject[2] = uc($aobject[2]);

    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Frontends \(Frontend, IsDefault\) VALUES \(\"$aobject[1]\", \"$aobject[2]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Frontends WHERE Frontend = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Frontend id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }

  # Insert a new Application
  if ($aobject[0] eq "a")
  {
    $aobject[4] =~ s/:/,/g;
    $aobject[5] = uc($aobject[5]);

    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Applications \(Application, VirtualHost, Target, Frontends, HotDeploy, NumberofVersions, DeployDate, Enterprise, ATAuth, PFView\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\", \"$aobject[4]\", \"$aobject[5]\", \"$aobject[6]\", \"$aobject[7]\", \"$aobject[8]\", \"$aobject[9]\", \"$aobject[10]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Applications WHERE Application = \"$aobject[1]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Application id: $row[0]\n";
      }
    }
    $query->finish;
    $dbh->disconnect;
  }

  # Insert a new log rule
  if ($aobject[0] eq "l")
  {
    $dbr="dbi:mysql:database=$database;host=localhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
    $query= $dbh->prepare("INSERT INTO Logs_Management \(Domain_Application, Relative_Path, Depth, Log_Pattern, Retention_Period, Action, Backup_Machine, Backup_User, Backup_Password, Backup_Path\) VALUES \(\"$aobject[1]\", \"$aobject[2]\", \"$aobject[3]\", \"$aobject[4]\", \"$aobject[5]\", \"$aobject[6]\", \"$aobject[7]\", \"$aobject[8]\", \"$aobject[9]\", \"$aobject[10]\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
    $query->finish;

    $query= $dbh->prepare("SELECT id FROM Logs_Management WHERE Domain_Application = \"$aobject[1]\" AND Relative_Path = \"$aobject[2]\" AND Depth = \"$aobject[3]\" AND Log_Pattern = \"$aobject[4]\" AND Retention_Period = \"$aobject[5]\" AND Action = \"$aobject[6]\" AND Backup_Machine = \"$aobject[7]\" AND Backup_User = \"$aobject[8]\" AND Backup_Password = \"$aobject[9]\" AND Backup_Path = \"$aobject[10]\"");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "Log rule id: $row[0]\n";
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

  # Delete domain
  if ($aobject[0] eq "d")
  {
    $table = "Domains";
    $column = "Domain";
  }
  elsif ($aobject[0] eq "s")
  {
    $table = "Servers";
    $column = "Server";
  }
  elsif ($aobject[0] eq "c")
  {
    $table = "Clusters";
    $column = "Cluster";
  }
  elsif ($aobject[0] eq "m")
  {
    $table = "Machines";
    $column = "Machine";
  }
  elsif ($aobject[0] eq "f")
  {
    $table = "Frontends";
    $column = "Frontend";
  }
  elsif ($aobject[0] eq "a")
  {
    $table = "Applications";
    $column = "Application";
  }
  elsif ($aobject[0] eq "l")
  {
    $table = "Logs_Management";
    $column = "id";
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
  if ($aobject[0] eq "d")
  {
    $table = "Domains";
    $column = "Domain";
  }
  elsif ($aobject[0] eq "s")
  {
    $table = "Servers";
    $column = "Server";
  }
  elsif ($aobject[0] eq "c")
  {
    $table = "Clusters";
    $column = "Cluster";
  }
  elsif ($aobject[0] eq "m")
  {
    $table = "Machines";
    $column = "Machine";
  }
  elsif ($aobject[0] eq "f")
  {
    $table = "Frontends";
    $column = "Frontend";
 }
  elsif ($aobject[0] eq "a")
  {
    $table = "Applications";
    $column = "Application";
  }
  elsif ($aobject[0] eq "e")
  {
    $table = "Application_Deploys";
    $column = "Application";
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
    if ($column eq "HotDeploy")
    {
      $aobject[3] = uc($aobject[3]);
    }

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

  if (($env ne "prd") and ($env ne "qua") and ($env ne "dev") and ($env ne "sandbox"))
  {
    print "Must define environment (PRD/QUA/DEV/SANDBOX)\n";
    usage;
  }
  else
  {
    $database = "Weblogic_" . uc($env);

    open(FILE, "$dbpassfile") or die $!;

    while (<FILE>)
    {
      chomp;
      $dbpass = $_;
    }

    close(FILE);
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
