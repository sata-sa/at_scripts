#!/usr/bin/perl
#set -x
use warnings;
use strict;
use threads;

use DBI;
use utf8;
use DateTime;
use MIME::Base64;
use Term::ANSIColor;
use Scalar::MoreUtils qw(empty);

########################
# Variable declaration #
########################
my $count = 0;
my $env;
my $dbr;
my $dbh;
my $dbpassfile = "/home/weblogic/etc/.wldbpass";
my $dbuser = "weblogic";
my $dbhost = "localhost";
my $dbpass;
my $database;
my $query;
my $option;
my $object;

########################
# Function declaration #
########################
sub usage
{
  print "Usage: $0 {PRD/QUA/DEV/SANDBOX} [OPTION] [DOMAIN/OBJECT]\n\n Options\n\n";
  print "  -servers [Domain]        : List all servers in the environment. If Domain is provided, will list servers from that domain only.\n";
  print "  -clusters [Domain]       : List all clusters in the environment. If Domain is provided, will list clusters from that domain only.\n";
  print "  -members [Domain]        : List servers and their related clusters and machines. If Domain is provided, will list servers from that domain only.\n";
  print "  -apptargets [Domain]     : List applications and their targets. If Domain is provided, will list applications from that domain only.\n";
  print "  -machines                : List all machines in the environment.\n";
  print "  -applications [Details]  : List all applications in the environment.\n";
  print "  -virtualhosts            : List all virtualhosts in the environment.\n";
  print "  -frontends [Details]     : List all frontends in the environment.\n";
  print "  -logs-management         : List logs management table information.\n";
  print "  -atauth                  : List if ATAuth library is ENABLE.\n";
  print "  -pfview                  : List if PFView library is ENABLE.\n";
  print "  -company                 : List Application and Company Name.\n";
  print "\n";
  exit;
}

sub list_all_domains
{
  my $href;
  my @tables = qw(Domains Domains_Legacy);
  my $table;
  my $id = 0;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    $query= $dbh->prepare("SELECT * FROM $table");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while ($href = $query->fetchrow_hashref)
      {
        $id++;
        print "$id:$href->{Domain}:$href->{WLS_Version}:$href->{JDK_Version}:$href->{Host}:$href->{Port}:$href->{User}:$href->{Password}:$href->{Location}\n";
      }
    }
  }

  $query->finish();
  $dbh->disconnect;
}

sub isDomain
{
  my $href;
  my @tables = qw(Domains Domains_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    for $table (@tables)
    {
      $dbr="dbi:mysql:database=$database;host=$dbhost";
      $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Domain = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "D:$href->{Domain}:$href->{WLS_Version}:$href->{JDK_Version}:$href->{Host}:$href->{Port}:$href->{User}:$href->{Password}:$href->{Location}\n";
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isApplication
{
  my $href;
  my @tables = qw(Applications Applications_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Application = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          if ($table eq "Applications")
          {
            print "A:$href->{Application}:$href->{VirtualHost}:$href->{Target}:$href->{Frontends}:$href->{HotDeploy}:$href->{NumberofVersions}:$href->{DeployDate}\n";
          }
          else
          {
            print "A:$href->{Application}:$href->{VirtualHost}:$href->{Target}:$href->{Frontends}:$href->{HotDeploy}:$href->{NumberofVersions}:$href->{Static_Location}\n";
          }
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isServer
{
  my $href;
  my @tables = qw(Servers Servers_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Server = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "S:$href->{Server}:$href->{Domain}:$href->{Cluster}:$href->{Machine}\n";
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isCluster
{
  my $href;
  my @tables = qw(Clusters Clusters_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Cluster = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "C:$href->{Cluster}:$href->{Domain}\n";
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isVirtualhost
{
  my $href;
  my @tables = qw(Applications Applications_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY VirtualHost = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          if ($table eq "Applications")
          {
            print "V:$href->{VirtualHost}:$href->{Application}:$href->{Target}:$href->{Frontends}:$href->{HotDeploy}:$href->{NumberofVersions}\n";
          }
          else
          {
            print "V:$href->{VirtualHost}:$href->{Application}:$href->{Target}:$href->{Frontends}:$href->{HotDeploy}:$href->{NumberofVersions}:$href->{Static_Location}\n";
          }
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isMachine
{
  my $href;
  my @tables = qw(Machines Machines_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Machine = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "M:$href->{Machine}\n";
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub isFrontend
{
  my $href;
  my @tables = qw(Frontends);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Frontend = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "F:$href->{Frontend}:$href->{IsDefault}\n";
        }
        $query->finish();
        $dbh->disconnect;
        exit 0;
      }
    }
  }
}

sub listServers
{
  my @row;
  my @tables = qw(Servers Servers_Legacy);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    if (not empty ($_[0]))
    {
      $query= $dbh->prepare("SELECT Server FROM $table WHERE BINARY Domain = '$_[0]'");
    }
    else
    {
      $query= $dbh->prepare("SELECT Server FROM $table");
    }
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "$row[0]\n";
      }
    }
    $query->finish();
  }
  $dbh->disconnect;
}

sub listClusters
{
  my @row;
  my @tables = qw(Clusters Clusters_Legacy);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    if (not empty ($_[0]))
    {
      $query= $dbh->prepare("SELECT Cluster FROM $table WHERE BINARY Domain = '$_[0]'");
    }
    else
    {
      $query= $dbh->prepare("SELECT Cluster FROM $table");
    }
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "$row[0]\n";
      }
    }
    $query->finish();
  }
  $dbh->disconnect;
}

sub listMachines
{
  my @row;
  my @tables = qw(Machines Machines_Legacy);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    $query= $dbh->prepare("SELECT Machine FROM $table");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "$row[0]\n";
      }
    }
    $query->finish();
  }
  $dbh->disconnect;
}

sub listApplications
{
  my @row;
  my @tables = qw(Applications Applications_Legacy);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    if (not empty ($_[0]))
    {
      if ($_[0] eq "Details")
      {
        $query= $dbh->prepare("SELECT * FROM $table");
        $query->execute() or die "Unable to execute statement: " . $query->errstr;

        if ($query->rows != 0)
        {
          while (@row = $query->fetchrow())
          {
            if ($table eq "Applications")
            {
              print "$row[1]:$row[2]:$row[3]:$row[4]:$row[5]:$row[6]:$row[7]:$row[8]:$row[9]:$row[10]\n";
            }
            else
            {
              print "$row[1]:$row[2]:$row[3]:$row[4]:$row[5]:$row[6]:$row[7]:$row[8]\n";
            }
          }
        }
        $query->finish();
      }
    }
    else
    {
      $query= $dbh->prepare("SELECT Application FROM $table");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while (@row = $query->fetchrow())
        {
          print "$row[0]\n";
        }
      }
      $query->finish();
    }
  }
  $dbh->disconnect;
}

sub listVirtualhosts
{
  my @row;
  my @tables = qw(Applications Applications_Legacy);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    $query= $dbh->prepare("SELECT VirtualHost FROM $table WHERE VirtualHost NOT LIKE ''");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    if ($query->rows != 0)
    {
      while (@row = $query->fetchrow())
      {
        print "$row[0]\n";
      }
    }
    $query->finish();
  }
  $dbh->disconnect;
}

sub listMembers
{
  my $href;
  my @tables = qw(Servers Servers_Legacy);
  my $table;

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table WHERE BINARY Domain = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "$href->{Server}:$href->{Domain}:$href->{Cluster}:$href->{Machine}\n";
        }
      }
      $query->finish();
    }
  }
  else
  {
    $dbr="dbi:mysql:database=$database;host=$dbhost";
    $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT * FROM $table");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "$href->{Server}:$href->{Domain}:$href->{Cluster}:$href->{Machine}\n";
        }
      }
      $query->finish();
    }
  }
  $dbh->disconnect;
}

sub listAppTargets
{
  my $href;
  my @tables = qw(Applications Applications_Legacy);
  my @srvtables = qw(Servers Servers_Legacy);
  my @clutables = qw(Clusters Clusters_Legacy);
  my @objlist;
  my $table;
  my $srvtable;
  my $clutable;
  my $apptarget;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  if (not empty ($_[0]))
  {
    my $obj = $_[0];

    for $srvtable (@srvtables)
    {
      $query= $dbh->prepare("SELECT Server FROM $srvtable WHERE BINARY Domain = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          push(@objlist, $href->{Server});
        }
      }
      $query->finish();
    }

    for $clutable (@clutables)
    {
      $query= $dbh->prepare("SELECT Cluster FROM $clutable WHERE BINARY Domain = '$obj'");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          push(@objlist, $href->{Cluster});
        }
      }
      $query->finish();
    }

    for $table (@tables)
    {
      for $apptarget (@objlist)
      {
        $query= $dbh->prepare("SELECT Application, Target FROM $table WHERE BINARY Target LIKE '$apptarget'");
        $query->execute() or die "Unable to execute statement: " . $query->errstr;

        if ($query->rows != 0)
        {
          while ($href = $query->fetchrow_hashref)
          {
            print "$href->{Application}:$href->{Target}\n";
          }
        }
        $query->finish();
      }
    }
  }
  else
  {
    for $table (@tables)
    {
      $query= $dbh->prepare("SELECT Application, Target FROM $table");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "$href->{Application}:$href->{Target}\n";
        }
      }
      $query->finish();
    }
  }
  $dbh->disconnect;
}

sub listFrontends
{
  my $href;
  my @tables = qw(Frontends);
  my $table;

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";

  for $table (@tables)
  {
    if (not empty ($_[0]))
    {
      if ($_[0] eq "Details")
      {
        $query= $dbh->prepare("SELECT * FROM $table");
        $query->execute() or die "Unable to execute statement: " . $query->errstr;

        if ($query->rows != 0)
        {
          while ($href = $query->fetchrow_hashref)
          {
            print "$href->{Frontend}:$href->{IsDefault}\n";
          }
        }
        $query->finish();
      }
    }
    else
    {
      $query= $dbh->prepare("SELECT Frontend FROM $table");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;

      if ($query->rows != 0)
      {
        while ($href = $query->fetchrow_hashref)
        {
          print "$href->{Frontend}\n";
        }
      }
      $query->finish();
    }
  }
  $dbh->disconnect;
}

sub listLogsManagement
{
  my $href;
  my $table = qw(Logs_Management);

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      print "LM:$href->{id}:$href->{Domain_Application}:$href->{Relative_Path}:$href->{Depth}:$href->{Log_Pattern}:$href->{Retention_Period}:$href->{Action}:$href->{Backup_Machine}:$href->{Backup_User}:$href->{Backup_Password}:$href->{Backup_Path}\n";
    }
  }
  $query->finish();
  $dbh->disconnect;
}

sub listAtauth
{
  my $href;
  my $table = qw(Applications);

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      print "Cluster:$href->{Target}:ATAuth:$href->{ATAuth}\n";
    }
  }
  $query->finish();
  $dbh->disconnect;
}


sub listPfview
{
  my $href;
  my $table = qw(Applications);

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      print "Cluster:$href->{Target}:PFView:$href->{PFView}\n";
    }
  }
  $query->finish();
  $dbh->disconnect;
}


######################
sub listCompany
{
  my $href;
  my $table = qw(Applications);

  $dbr="dbi:mysql:database=$database;host=$dbhost";
  $dbh = DBI->connect($dbr, $dbuser, $dbpass) or die "Unable to connect to database $dbr: $!";
  $query= $dbh->prepare("SELECT * FROM $table");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      print "Application:$href->{Application}:Company:$href->{Enterprise}\n";
    }
  }
  $query->finish();
  $dbh->disconnect;
}





######################
# List domain object #
######################
sub list_domain_objects
{
  my @row;

  if ((not empty ($object)) and (empty ($option)))
  {
    # Check if object is a domain
    isDomain $object;

    # Check if object is an application
    isApplication $object;

    # Check if object is a server
    isServer $object;

    # Check if object is a cluster
    isCluster $object;

    # Check if object is a Virtualhost
    isVirtualhost $object;

    # Check if object is a Machine
    isMachine $object;

    # Check if object is a Frontend
    isFrontend $object;
  }
  else
  {
    if ($option eq "-servers")
    {
      listServers $object;
    }
    elsif ($option eq "-clusters")
    {
      listClusters $object;
    }
    elsif ($option eq "-machines")
    {
      listMachines;
    }
    elsif ($option eq "-applications")
    {
      listApplications $object;
    }
    elsif ($option eq "-virtualhosts")
    {
      listVirtualhosts;
    }
    elsif ($option eq "-members")
    {
      listMembers $object;
    }
    elsif ($option eq "-apptargets")
    {
      listAppTargets $object;
    }
    elsif ($option eq "-frontends")
    {
      listFrontends $object;
    }
    elsif ($option eq "-logs-management")
    {
      listLogsManagement $object;
    }
    elsif ($option eq "-atauth")
    {
      listAtauth $object;
    }
    elsif ($option eq "-pfview")
    {
      listPfview $object;
    }
    elsif ($option eq "-company")
    {
      listCompany $object;
    }
}
}
########################
# Main execution block #
########################
if ($#ARGV > -1)
{
  $env = lc($ARGV[0]);

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

  if ($#ARGV == 0)
  {
    list_all_domains;
  }
  else
  {
    foreach (1 .. $#ARGV)
    {
      if (($ARGV[$_] eq "-servers") or ($ARGV[$_] eq "-clusters") or ($ARGV[$_] eq "-machines") or ($ARGV[$_] eq "-applications") or ($ARGV[$_] eq "-members") or ($ARGV[$_] eq "-virtualhosts") or ($ARGV[$_] eq "-apptargets") or ($ARGV[$_] eq "-frontends") or ($ARGV[$_] eq "-logs-management") or ($ARGV[$_] eq "-atauth") or ($ARGV[$_] eq "-pfview") or ($ARGV[$_] eq "-company"))
      {
        $option = $ARGV[$_];
      }
      else
      {
        $object = $ARGV[$_];
      }
    }
    # Check infrastructure objects
    list_domain_objects;
  }
}
else
{
  usage;
}
