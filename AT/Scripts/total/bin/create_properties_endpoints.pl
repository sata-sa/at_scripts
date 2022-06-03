#!/usr/bin/perl

use warnings;
use strict;
use DBI;
use utf8;
use File::Basename;
use Scalar::MoreUtils qw(empty);

my @envlist = qw(APPLICATION_NAME DOMAIN_NAME MACHINE_NAME SERVER_LISTEN_ADDRESS SERVER_LISTEN_PORT SERVER_NAME VIRTUALHOST_NAME DOMAIN_HOME WLS_BASE ENV);
my @endpoints_properties = qw(password url);
my $endpoints_primary_key = "username";
my $endpoints_name = "endpoints.properties";
my $destination_path;
my $app_properties;
my %keys;
my $dbr;
my $dbh;
#my $dbuser = "gpgs";
my $dbuser = "webservpass";
my $dbserver = "sumonitor05.ritta.local";
my $database = "gpgs";
#my $dbpass = "0mega2013#";
my $dbpass = "0mega2015#";

sub usage
{
  print "Usage: ".basename($0)." <APPLICATION PROPERTIES> <DESTINATION PATH>\n";
  exit 0;
}

#######################################################################################
# Connect to GPGs database - Failsafe measure if there is no webservice for passwords #
#######################################################################################
sub db_connect
{
  $dbr="dbi:mysql:database=$database;host=$dbserver";
}

##############################################
# Open files and check destination directory #
##############################################
sub open_files
{
  # Open application properties file
  if (-e "$ARGV[0]")
  {
    open FILEA, "$ARGV[0]" or die $!;
    $app_properties = "$ARGV[0]";
  }
  else
  {
    print "File ".$ARGV[0]." not found.\n";
    exit 1;
  }

  # Check destination directory existance
  if (-d "$ARGV[1]")
  {
    $destination_path = "$ARGV[1]";
  }
  else
  {
    print "Directory $ARGV[1] not present\n";
    exit 1;
  }
}

######################################
# Prepare output files to be written #
######################################
sub prepare_out_files
{
  # Prepare endpoints file
  if (-e "$destination_path/$endpoints_name")
  {
    open FILEB, ">>$destination_path/$endpoints_name" or die $!;
  }
  else
  {
    open FILEB, ">$destination_path/$endpoints_name" or die $!;
  }

  # Prepare new application properties file
  open FILEC, ">$destination_path/".basename($app_properties) or die $!;
}

###################################################
# Check for the presence of environment variables #
###################################################
sub check_env_vars
{
  my $key;

  if (! -s "$destination_path/$endpoints_name")
  {
    print FILEB "# ".(localtime)."\n#\n";

    for $key (@envlist)
    {
      unless ($ENV{$key})
      {
        print "Key $key not present in environment\n";
        exit 1;
      }
      else
      {
        print FILEB "# $key = ".$ENV{$key}."\n";
      }
    }
    print FILEB "#\n";
  }
}

################################################################
# Read keys and values from application properties into memory #
################################################################
sub load_keys
{
  my $envvar;
  my $key;
  my $val;

  while (<FILEA>)
  {
    if (/^#/)
    {
      next;
    }

    if(($key, $val) = /^(.*)?=(.*)$/)
    {
      chomp($key);
      $key =~ s/^\s*(.*?)\s*$/$1/g;
      chomp($val);
      $val =~ s/^\s*(.*?)\s*$/$1/g;

      # Replace environment values
      for $envvar (@envlist)
      {
        $val =~ s/\$\{$envvar\}/$ENV{$envvar}/g;
      }

      $keys{$key} = $val;
    }
  }
  close(FILEA);
}

#########################
# Populate output files #
#########################
sub populate_files
{
  my $line_printed = "N";
  my $property;
  my $password;
  my $envvar;
  my $query;
  my $nkey;
  my $key;
  my $val;

  # Reopen application properties file
  open FILEA, "$app_properties" or die $!;

  while (<FILEA>)
  {
    if (/^#/)
    {
      print FILEC $_;
      next;
    }
    else
    {
      # Replace environment values
      for $envvar (@envlist)
      {
        $_ =~ s/\$\{$envvar\}/$ENV{$envvar}/g;
      }

      if(($key, $val) = /^(.*)?=(.*)$/)
      {
        chomp($key);
        $key =~ s/^\s*(.*?)\s*$/$1/;
        chomp($val);
        $val =~ s/^\s*(.*?)\s*$/$1/;

        if ($key =~ /\.$endpoints_primary_key/)
        {
          print FILEB "$key = $keys{$key}\n";

          for $property (@endpoints_properties)
          {
            $nkey = $key;
            $nkey =~ s/\.$endpoints_primary_key/\.$property/;

            if ("$property" eq "password")
            {
              # First step - Check if password is not null in application properties file
              if (not empty($keys{$nkey}))
              {
                $password = $keys{$nkey};
              }
              else
              {
                $password = `webservice_seguranca_obter_password.sh $ENV{ENV} $keys{$key}`;
                chomp($password);

                if ($password eq "UNABLE_TO_GET_PWD_FROM_WS_DSS_AREA_SEGURANCA")
                {
                  $dbr="dbi:mysql:database=$database;host=$dbserver";

                  if ($dbh = DBI->connect($dbr, $dbuser, $dbpass))
                  {
                    $query = $dbh->prepare("SELECT Password FROM webservices_passwords WHERE Username like '$keys{$key}'");
                    $query->execute();

                    if ($query->rows != 0)
                    {
                      $password = $query->fetchrow_hashref->{Password};
                      print "Password obtained from internal database for user $keys{$key}";
                    }
                    else
                    {
                      $password = "UNABLE_TO_OBTAIN_PASSWORD";
                    }
                  }
                  else
                  {
                    $password = "UNABLE_TO_OBTAIN_PASSWORD";
                  }
                }
                elsif ($password eq "WS_DSS_AREA_SEGURANCA_DISABLED_IN_THIS_ENVIRONMENT")
                {
                  $password = "WS_DSS_AREA_SEGURANCA_DISABLED_IN_THIS_ENVIRONMENT"
                }
              }
              print FILEB "$nkey = $password\n";
            }
            else
            {
              if (not empty($keys{$nkey}))
              {
                print FILEB "$nkey = $keys{$nkey}\n";
              }
            }
          }
        }
        else
        {
          for $property (@endpoints_properties)
          {
            if ($key =~ /\.$property/)
            {
              $nkey = $key;
              $nkey =~ s/\.$property/\.$endpoints_primary_key/;

              if (empty($keys{$nkey}))
              {
                print FILEC $_;
                $line_printed = "Y";
              }
              else
              {
                $line_printed = "Y";
              }
            }
          }

          if ($line_printed eq "Y")
          {
            $line_printed = "N";
            next;
          }
          else
          {
            print FILEC $_;
          }
        }
      }
      else
      {
        print FILEC $_;
      }
    }
  }
}

########################
# Main execution block #
########################
if ($#ARGV < 1)
{
  usage;
}
else
{
  open_files;
  prepare_out_files;
  check_env_vars;
  load_keys;
  populate_files;
}

exit 0;
