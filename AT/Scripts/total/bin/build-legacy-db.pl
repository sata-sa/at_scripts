#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use MIME::Base64;
use utf8;
use Scalar::MoreUtils qw(empty);

my $wls_parser = "get-wls-object-list.pl";
my $dbpassfile = "/home/weblogic/etc/.wldbpass";
my $dbuser = "weblogic";
my $dbhost = "localhost";
my $database;
my $dbpass;
my $tmp_dir = "/var/tmp";
my $env;
my $query;
my @domains_list;
my $dbh;
my $dbr;
my @frontends_list_prd = qw(suhttp101 suhttp102);
my @frontends_list_qua = qw(suhttp301);
my @frontends_list_dev = qw(suhttp201);
my $static_location;
my $deploydate;

sub purge_tables
{
  my @row;
  my @tables;
  my $table;

  print "Purge tables\n";

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

sub get_wls_version
{
  if ( "$_[0]" eq "bea1211" )
  {
    return "12.1.1";
  }
  elsif ( "$_[0]" eq "bea1020" )
  {
    return "10.2.0";
  }
  elsif ( "$_[0]" eq "bea1030" )
  {
    return "10.3.0";
  }
  elsif ( "$_[0]" eq "bea1033" )
  {
    return "10.3.3";
  }
  elsif ( "$_[0]" eq "bea1001" )
  {
    return "10.0.1";
  }
  elsif ( "$_[0]" eq "bea1032" )
  {
    return "10.3.2";
  }
  elsif ( "$_[0]" eq "bea922" )
  {
    return "9.2.2";
  }
  elsif ( "$_[0]" eq "bea812" )
  {
    return "8.1.2";
  }
  elsif ( "$_[0]" eq "bea813" )
  {
    return "8.1.3";
  }
  elsif ( "$_[0]" eq "bea816" )
  {
    return "8.1.6";
  }
  elsif ( "$_[0]" eq "bea815" )
  {
    return "8.1.5";
  }
  else
  {
    return "NA";
  }
}

sub get_jdk_version
{
  if ( "$_[0]" eq "jdk141_05" )
  {
    return "1.4.1_05";
  }
  elsif ( "$_[0]" eq "jdk142_04" )
  {
    return "1.4.2_04";
  }
  elsif ( "$_[0]" eq "jdk142_08" )
  {
    return "1.4.2_08";
  }
  elsif ( "$_[0]" eq "jdk142_11" )
  {
    return "1.4.2_11";
  }
  elsif ( "$_[0]" eq "jdk150_10" )
  {
    return "1.5.0_10";
  }
  elsif ( "$_[0]" eq "jdk150_11" )
  {
    return "1.5.0_11";
  }
  elsif ( "$_[0]" eq "jdk160_05" )
  {
    return "1.6.0_05";
  }
  elsif ( "$_[0]" eq "jdk160_14" )
  {
    return "1.6.0_14";
  }
  elsif ( "$_[0]" eq "jdk160_16" )
  {
    return "1.6.0_16";
  }
  elsif ( "$_[0]" eq "jdk160_18" )
  {
    return "1.6.0_18";
  }
  elsif ( "$_[0]" eq "jdk1.7.0_07" )
  {
    return "1.7.0_07";
  }
  else
  {
    return "NA";
  }
}

sub build_domains_list
{
  my @new_domain_list;
  my @domain_list;
  my $domain_name;
  my $wls_version;
  my $jdk_version;
  my $location;
  my @path;
  my @domain;
  my $host;
  my $port;
  my $entry;
  my $user;
  my $password;

  print "Build Domains list\n";

  # Process domain entries for old infrastructure
  if ($env eq "prd")
  {
    @domain_list=`ssh weblogic\@suapp301.ritta.local cat /export/home/weblogic/etc/domains_prod.lst | grep -v "^#" | sort`;
  }
  elsif ($env eq "qua")
  {
    @domain_list=`ssh weblogic\@suapp301.ritta.local cat /export/home/weblogic/etc/domains_qual.lst | grep -v "^#" | sort`;
  }
  elsif ($env eq "dev")
  {
    @domain_list=`ssh weblogic\@suapp301.ritta.local cat /export/home/weblogic/etc/domains_devel.lst | grep -v "^#" | sort`;
  }

  foreach $entry (@domain_list)
  {
    @domain = split(':', $entry, 10);
    $domain_name = $domain[0];
    $wls_version = get_wls_version($domain[5]);
    $jdk_version = get_jdk_version($domain[6]);
    $host = $domain[1];
    $port = $domain[2];
    $user = $domain[3];
    $password = $domain[4];
    $static_location = $domain[8];
    $location = "/softs/apps/$domain[5]/user_projects/domains/$domain[0]";

    if ((split('\.', $wls_version, 3))[0] ne "8")
    {
      system("scp weblogic\@$host:$location/config/config.xml $tmp_dir/$domain_name.$env.xml");
    }
    else
    {
      system("scp weblogic\@$host:$location/config.xml $tmp_dir/$domain_name.$env.xml");
    }

    if (not empty($static_location))
    {
      push(@domains_list,"$domain_name:$wls_version:$jdk_version:$host:$port:$user:$password:$location:$static_location");
    }
    else
    {
      push(@domains_list,"$domain_name:$wls_version:$jdk_version:$host:$port:$user:$password:$location:");
    }
  }

  # Process domain entries for new infrastructure
  if ($env eq "prd")
  {
    $host = "sudomain101.ritta.local";
    $jdk_version = "1.6.0_18";
  }
  elsif ($env eq "qua")
  {
    $host = "sudomain301.ritta.local";
    $jdk_version = "1.6.0_23";
  }

  @new_domain_list = `ssh weblogic\@$host find /weblogic -mindepth 1 -maxdepth 1`;
  $password = `ssh weblogic\@$host cat /home/weblogic/.default_password`;
  $user = "weblogic";
  chomp($password);

  foreach (@new_domain_list)
  {
    @path = split('/', $_, 3);
    chomp($path[2]);
    $domain_name = $path[2];
    $wls_version = "10.3.3";
    $location = $_;
    chomp($location);

    system("scp weblogic\@$host:/weblogic/$domain_name/config/config.xml $tmp_dir/$domain_name.$env.xml");
    $port = `$wls_parser $tmp_dir/$domain_name.$env.xml -listenport | cut -d\: -f 2`;
    chomp($port);

    push(@domains_list,"$domain_name:$wls_version:$jdk_version:$host:$port:$user:$password:$location"); 
  }
}

sub populate_legacy_tables
{
  my $domain_name;
  my $wls_version;
  my $jdk_version;
  my @domain;
  my @servers_list;
  my @machines_list;
  my @clusters_list;
  my $user;
  my $password;
  my $location;
  my $host;
  my $port;
  my $entry;
  my $server;
  my $server_name;
  my $cluster_name;
  my $machine_name;
  my $href;
  my $frontend;
  my @frontends_list;

  print "Populating legacy tables\n";

  foreach $entry (@domains_list)
  {
    @domain = split(':', $entry, 8);
    $domain_name = $domain[0];
    $wls_version = $domain[1];
    $jdk_version = $domain[2];
    $host = $domain[3];
    $port = $domain[4];
    $user = $domain[5];
    $password = $domain[6];
    $location = $domain[7];

    # Domains_Legacy
    $query= $dbh->prepare("INSERT INTO Domains_Legacy \(Domain, WLS_Version, JDK_Version, Host, Port, User, Password, Location\) VALUES \(\"$domain_name\", \"$wls_version\", \"$jdk_version\", \"$host\", \"$port\", \"$user\", \"$password\", \"$location\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;

    # Servers_Legacy
    @servers_list = `$wls_parser $tmp_dir/$domain_name.$env.xml all -members`;

    foreach $server (@servers_list)
    {
      $server_name = (split(':', $server, 3))[0];
      chomp($server_name);
      $cluster_name = (split(':', $server, 3))[1];
      chomp($cluster_name);
      $machine_name = (split(':', $server, 3))[2];
      chomp($machine_name);

      $query= $dbh->prepare("INSERT INTO Servers_Legacy \(Server, Domain, Cluster, Machine\) VALUES \(\"$server_name\", \"$domain_name\", \"$cluster_name\", \"$machine_name\"\)");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;
    }

    # Clusters_Legacy
    @clusters_list = `$wls_parser $tmp_dir/$domain_name.$env.xml cluster `;

    foreach $cluster_name (@clusters_list)
    {
      chomp($cluster_name);
      $query= $dbh->prepare("INSERT INTO Clusters_Legacy \(Cluster, Domain\) VALUES \(\"$cluster_name\", \"$domain_name\"\)");
      $query->execute() or die "Unable to execute statement: " . $query->errstr;
    }
  }

  # Machines_Legacy
  $query= $dbh->prepare("SELECT DISTINCT(Machine) FROM Servers_Legacy WHERE Machine NOT LIKE ''");
  $query->execute() or die "Unable to execute statement: " . $query->errstr;

  if ($query->rows != 0)
  {
    while ($href = $query->fetchrow_hashref)
    {
      push(@machines_list, $href->{Machine});
    }
  }

  for $machine_name (@machines_list)
  {
    $query= $dbh->prepare("INSERT INTO Machines_Legacy \(Machine\) VALUES \(\"$machine_name\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
  }

  # Virtualhost_Legacy
  #if ($env eq "prd")
  #{
  #  @frontends_list = @frontends_list_prd;
  #}
  #elsif ($env eq "qua")
  #{
  #  @frontends_list = @frontends_list_qua;
  #}
  #else
  #{
  #  @frontends_list = @frontends_list_dev;
  #}

  #for $frontend (@frontends_list)
  #{
  #  $query= $dbh->prepare("INSERT INTO Frontends_Legacy \(Frontend, IsDefault\) VALUES \(\"$frontend\", \"Y\"\)");
  #  $query->execute() or die "Unable to execute statement: " . $query->errstr;
  #}
}

##################################
# Build Virtualhost_Legacy table #
##################################
sub vhost_legacy
{
  my @vhosts_list;
  my $target;
  my @path;
  my $vhost;
  my $appname;
  my $host;
  my $domain_name;
  my @app_list;
  my $appentry;
  my $frontends;
  my $numberofversions;

  if ($env eq "prd")
  {
    $host = "sudomain101.ritta.local";
    $frontends = "suvhttpgold101,suvhttpgold102,suvhttpgold103,suvhttpgold104";
    @vhosts_list = `ssh weblogic\@$host find /data -name \.targets -type f`;
  }
  elsif ($env eq "qua")
  {
    $host = "sudomain301.ritta.local";
    $frontends = "suhttp301";
    @vhosts_list = `ssh weblogic\@$host find /data -name \.targets -type f`;
  }
  else
  {
    $host = "NULL_HOST";
  }

  # New Infrastructure
  foreach (@vhosts_list)
  {
    $target = `ssh weblogic\@$host cat $_`;
    chomp($target);
    @path = split('/', $_, 6);
    $vhost = $path[2];
    chomp($vhost);
    $appname = $path[4];
    chomp($appname);

    if (($appname eq "ssa") or ($appname eq "sds"))
    {
      $numberofversions = 1;
    }
    else
    {
      $numberofversions = 2;
    }

    if (($appname eq "factemipf") or ($appname eq "factemisv") or ($appname eq "few3") or ($appname eq "fews"))
    {
      if ($env eq "prd")
      {
        $deploydate = "Tuesday;12.30-14|Thursday;12.30-14";
      }
      else
      {
        $deploydate = "NOTSET";
      }
    }
    elsif (($appname eq "sefweb"))
    {
      $numberofversions = 1;

      if ($env eq "prd")
      {
        $deploydate = "Tuesday;7-9|Thursday;7-9";
      }
      else
      {
        $deploydate = "NOTSET";
      }
    }
    else
    {
      $deploydate = "NOTSET";
    }

    $query= $dbh->prepare("INSERT INTO Applications_Legacy \(Application, VirtualHost, Target, Frontends, HotDeploy, NumberofVersions, DeployDate, Static_Location\) VALUES \(\"$appname\", \"$vhost\", \"$target\", \"$frontends\", \"DISABLE\", \"$numberofversions\", \"$deploydate\", \"\"\)");
    $query->execute() or die "Unable to execute statement: " . $query->errstr;
  }

  # Old Infrastructure
  foreach (@domains_list)
  {
    $domain_name = (split(':', $_, 9))[0];
    $static_location = (split(':', $_, 9))[8];
    chomp($static_location);
    $host = (split(':', $_, 9))[3];

    if (length($static_location) > 0)
    {
      $frontends = $host;
    }

    if (($host ne "sudomain101.ritta.local") && ($host ne "sudomain301.ritta.local") && ($host ne "NULL_HOST"))
    {
      
      @app_list = `$wls_parser $tmp_dir/$domain_name.$env.xml -apptargets`;

      for $appentry (@app_list)
      {
        $appname = (split(':', $appentry, 2))[0];
        $appname = (split('#', $appname, 2))[0];
        chomp($appname);
        $target = (split(':', $appentry, 2))[1];
        chomp($target);

        if (length($static_location) > 0)
        {
          $query= $dbh->prepare("INSERT INTO Applications_Legacy \(Application, VirtualHost, Target, Frontends, HotDeploy, NumberofVersions, DeployDate, Static_Location\) VALUES \(\"$appname\", \"\", \"$target\", \"$frontends\", \"DISABLE\", \"1\", \"NOTSET\", \"$static_location\"\)");
        }
        else
        {
          $query= $dbh->prepare("INSERT INTO Applications_Legacy \(Application, VirtualHost, Target, Frontends, HotDeploy, NumberofVersions, DeployDate, Static_Location\) VALUES \(\"$appname\", \"\", \"$target\", \"\", \"DISABLE\", \"1\", \"NOTSET\", \"\"\)");
        }
        $query->execute() or die "Unable to execute statement: " . $query->errstr;
      }
      $static_location = "";
      $frontends = "";
    }
  }
  $query->finish();
  $dbh->disconnect;
}

########################
#                      #
# Main execution block #
#                      #
########################
if ($#ARGV > -1)
{
  print "started";
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
  build_domains_list;
  populate_legacy_tables;
  vhost_legacy;
}
else
{
  print "Must define environment (PRD/QUA/DEV/SANDBOX).\n";
  exit 1;
}

