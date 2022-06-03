#!/usr/bin/perl -CA
use warnings;
use strict;

use File::Basename;
use MediaWiki::API;
use utf8;
#use LWP::UserAgent 2;

my $title_prefix = 'WL_AppDeploys';
my $server = 'https://sumonitor05.ritta.local/api.php';
my $dbserver= 'sumonitor05.ritta.local';
my $loginname = 'bot';
my $loginpwd = 'b0t2012#';
my $sectionid = 0;
my $contents;
my $timestamp;
my $title;
my $page;
my $wadtitle = "WebLogic_Application_Deployments";

my $application = $ARGV[0];   # Name of the application being updated
my $file = $ARGV[1];          # Name of the deployed file
my $ipaddr = $ARGV[2];        # IP Address from the machine that started the deployment
my $state = $ARGV[3];         # Was the deployment successfull?
my $env = $ARGV[4];           # Document section - Production/Quality

#my @timeData = gmtime(time);
my @timeData = localtime(time);

my $year = $timeData[5] + 1900;
my $month = sprintf("%02d", $timeData[4] + 1);
my $day = sprintf("%02d", $timeData[3]);
my $hour = sprintf("%02d", $timeData[2]);
my $minutes = sprintf("%02d", $timeData[1]);
my $seconds = sprintf("%02d", $timeData[0]);
my $date = "$year/$month/$day $hour:$minutes:$seconds";

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

sub usage_mwupd
{
  print "Usage: ".basename($0)." <Application Name> <Uploaded File> <Uploading Machine IP Address> <Upload State> <Environment (PRD/QUA)>\n";
}

if ($#ARGV < 4)
{
  usage_mwupd();
  exit 1;
}

########################
# MediaWiki page title #
########################
if (uc("$env") eq "PRD")
{
  $title = "$title_prefix"."_"."PRD"."_"."$year";
}
elsif (uc("$env") eq "QUA")
{
  $title = "$title_prefix"."_"."QUA"."_"."$year";
}
else
{
  die "Environment must be PRD or QUA\n";
}

my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = $server;

# Log in to MediaWiki
$mw->login( { lgname => $loginname, lgpassword => $loginpwd } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

#####################################################################################
# Check for WL_AppsDeploys_ENV_YEAR page existance and update or create accordingly #
#####################################################################################
$page = $mw->get_page( { title => $title } );

unless (defined $page->{missing}) 
{
  print "Updating MediaWiki page $title\n";

  $timestamp = $page->{timestamp}; # To avoid edit conflicts

  $contents = substr($page->{'*'},0,-2);

  $mw->edit( 
  {
    action => 'edit',
    title => $title,
    basetimestamp => $timestamp,
    text => "$contents"."|-\n|$application||$date||$file||$ipaddr||$state\n|}"
  } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
}
else
{
  print "Creating MediaWiki page $title and updating WebLogic_Application_Deployments page\n";

  #############################
  # Create new MediaWiki page #
  #############################
  $mw->edit(
  {
    action => 'edit',
    title => $title,
    createonly => 1,
    text => "{| class=\"wikitable sortable\" style=\"text-align:center\"\n"."! Aplicação || Data || Ficheiro || IP || Com sucesso?\n"."|-\n|$application||$date||$file||$ipaddr||$state\n|}\n"
  } )
  || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

  ##########################################################
  # Update MediaWiki WebLogic_Application_Deployments page #
  ##########################################################
  $wadtitle = "WebLogic_Application_Deployments";
  $page = $mw->get_page( { title => $wadtitle } );

  if (uc("$env") eq "PRD")
  {
    $sectionid = 1;
  }
  elsif (uc("$env") eq "QUA")
  {
    $sectionid = 2;
  }

  if ($sectionid)
  { 
    my $reference = $mw->api( {
      action => 'query',
      titles => $wadtitle,
      prop => 'revisions',
      rvsection => $sectionid,
      rvprop => 'content' } )
      || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

      my ($pageid, $pageref) = each %{$reference->{query}->{pages}};
      my $revision = @{$pageref->{revisions}}[0];
      my ($section, $contents) = %{$revision};
      $timestamp = $page->{timestamp}; # To avoid edit conflicts

      $mw->edit( 
      {
        action => 'edit',
        title => "WebLogic_Application_Deployments",
        section => $sectionid,
        basetimestamp => $timestamp,
        text => $contents."\n* [["."$title"." | "."$year"."]]" } )
        || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
  }
  else
  {
    die "Invalid section id\n";
  }
}

$mw->logout();

###############################
# Update deployments database #
###############################
$date = "$year$month$day$hour$minutes$seconds";

if ($state eq "Sim")
{
  $state="Y";
}
else
{
  $state="N";
}

system("bash", "-c", "wlappdeploys_updatedb.pl $date $application $file $ipaddr $state $env");

exit 0;
