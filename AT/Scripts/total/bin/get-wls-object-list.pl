#!/usr/bin/perl
#######################
# Recognized objects:
# - application
# - cluster
# - server
# - machine
#######################
use warnings;
use strict;
use XML::Twig;
use File::Basename;
use Scalar::MoreUtils qw(empty);

my $twig;
my $config_file="EMPTY";
my $object="EMPTY";
my $option="EMPTY";
my $arg;
my $wlsversion=10;
my $admin_name="EMPTY";
my $newappentry="N";
my $ident = "";

# Subroutine definition
sub print_name
{
  my($twig, $elt)= @_;

  if ($wlsversion == 8)
  {
    print ${$elt->atts}{'Name'}."\n";
  }
  else
  {
    print $elt->text."\n";
  }
  $twig->purge;
  return 1;
}

################################################
# Print application name (only war/ear files ) #
################################################
sub print_app_name
{
  my($twig, $elt)= @_;
  my $entry; my $tag; my $appname; my $apptype;

  if ($wlsversion == 8)
  {
    my $parent=$elt->parent;

    if ($newappentry ne ${$parent->atts}{'Name'})
    {
      $newappentry = ${$parent->atts}{'Name'};
      print $newappentry."\n";
    }
  }
  else
  {
    foreach $entry ($elt)
    {
      foreach $tag ($entry->getElementsByTagName('module-type'))
      {
        $apptype = $tag->text;
      }

      if (($apptype ne "war") && ($apptype ne "ear"))
      {
        next;
      }

      foreach $tag ($entry->getElementsByTagName('name'))
      {
        $appname = $tag->text;
      }
      print $appname."\n";
    }
  }
  $twig->purge;
  return 1;
}

################################
# Print objects and their type #
################################
sub print_name_with_type
{
  my($twig, $elt)= @_;
  my $tag; my $entry; my $appname; my $apptype="EMPTY";

  my $parent=$elt->parent;

  if ($wlsversion == 8)
  {
    if ($elt->tag eq "WebAppComponent")
    {
      if ($newappentry ne ${$parent->atts}{'Name'})
      {
        print "Application:".${$parent->atts}{'Name'}."\n";
        $newappentry = ${$parent->atts}{'Name'};
      }
    }
    else
    {
      print $elt->tag.":".${$elt->atts}{'Name'}."\n";
    }
  }
  else
  {
    if ($elt->tag eq "app-deployment")
    {
      foreach $entry ($elt)
      {
        foreach $tag ($entry->getElementsByTagName('module-type'))
        {
          $apptype = $tag->text;
        }

        if (($apptype ne "war") && ($apptype ne "ear"))
        {
          next;
        }

        foreach $tag ($entry->getElementsByTagName('name'))
        {
          $appname = $tag->text;
        }
        print "Application:".$appname."\n";
      }
    }
    else
    {
      print uc(substr($parent->tag, 0, 1)).substr($parent->tag, 1).":".$elt->text."\n";
    }
  }
  $twig->purge;
  return 1;
}

################################################
# Print clusters name defined in WebLogic file #
################################################
sub print_cluster_members
{
  my($twig, $elt)= @_;
  my $sname; my $cname; my $entry; my $tag;

  foreach $entry ($elt)
  {
    if ($wlsversion == 8)
    {
      $sname=${$entry->atts}{'Name'};
      $cname=${$entry->atts}{'Cluster'};
    }
    else
    {
      $sname=$entry->first_child->text;

      foreach $tag ($entry->getElementsByTagName('cluster'))
      {
        $cname = $tag->text;
      }
    }

    if (not empty ($cname))
    {
      print $cname.":".$sname."\n";
    }
  }
  $twig->purge;
  return 1;
}

################################################
# Print machines name defined in WebLogic file #
################################################
sub print_machine_members
{
  my($twig, $elt)= @_;
  my $sname; my $mname; my $entry; my $tag;

  foreach $entry ($elt)
  {
    if ($wlsversion == 8)
    {
      $sname=${$entry->atts}{'Name'};
      $mname=${$entry->atts}{'Machine'};
    }
    else
    {
      $sname=$entry->first_child->text;

      foreach $tag ($entry->getElementsByTagName('machine'))
      {
        $mname = $tag->text;
      }
    }

    if (not empty ($mname))
    {
      print $mname.":".$sname."\n";
    }
  }
  $twig->purge;
  return 1;
}

###############################################
# Print servers name defined in WebLogic file #
###############################################
sub print_server_members
{
  my($twig, $elt)= @_;
  my $sname; my$cname; my $mname; my $entry; my $tag;

  foreach $entry ($elt)
  {
    if ($wlsversion == 8)
    {
      $sname=${$entry->atts}{'Name'};
      $mname=${$entry->atts}{'Machine'};
      $cname=${$entry->atts}{'Cluster'};
    }
    else
    {
      $sname=$entry->first_child->text;

      foreach $tag ($entry->getElementsByTagName('machine'))
      {
        $mname = $tag->text;
      }

      foreach $tag ($entry->getElementsByTagName('cluster'))
      {
        $cname = $tag->text;
      }
    }

    if ((not empty($mname)) && (not empty($cname)))
    {
      print $sname.":".$cname.":".$mname."\n";
    }
    elsif (not empty($cname))
    {
      print $sname."::".$cname."\n";
    }
    else
    {
      print $sname."::\n";
    }
  }
  $twig->purge;
  return 1;
}

#############################################
# Get the domain administration server name #
#############################################
sub get_admin_name()
{
  my($twig, $elt)= @_;

  $admin_name=$elt->text;

  $twig->purge;
  return 1;
}

######################################################
# Print the domain administration server listen port #
######################################################
sub print_listen_port()
{
  my($twig, $elt)= @_;
  my $entry; my $parent; my $tag;
  
  foreach $entry ($elt)
  {
    my $parent=$entry->parent;

    foreach $tag ($parent->getElementsByTagName('name'))
    {
      if (("$admin_name" eq $tag->text) && ("$object" ne "server"))
      {
        print $tag->text.":".$entry->text."\n";
        $twig->purge;
        exit 0;
      }
      else
      {
        print $tag->text.":".$entry->text."\n";
      }
    }
  }
  $twig->purge;
  return 1;
}

#################################################
# Check if configuration file is for WebLogic 8 #
#################################################
sub check_wl_version()
{
  $twig = XML::Twig->new(twig_roots => {"Domain" => 1}, TwigHandlers => {"Domain" => \&check_domain_version});
  $twig->parsefile("$config_file");
}

############################
# Check the domain version #
############################
sub check_domain_version()
{
  my($twig, $elt)= @_;

  if (substr((${$elt->atts}{'ConfigurationVersion'}), 0, 1) == 8)
  {
    $wlsversion = 8;
  }
  $twig->purge;
  return 1;
}

########################################
# Print applications and their targets #
########################################
sub print_app_targets()
{
  my($twig, $elt)= @_;
  my $entry; my $tag; my $appname; my $apptarget; my $apptype;

  foreach $entry ($elt)
  {
    if ($wlsversion == 8)
    {
      my $parent=$entry->parent;

      if ($newappentry ne ${$parent->atts}{'Name'})
      {
        $appname = ${$parent->atts}{'Name'};
        $apptarget = ${$entry->atts}{'Targets'};
        $newappentry = $appname;
      }
      else
      {
        next;
      }
    }
    else
    {
      foreach $tag ($entry->getElementsByTagName('module-type'))
      {
        $apptype = $tag->text;
      }

      if (($apptype ne "war") && ($apptype ne "ear"))
      {
        next;
      }

      foreach $tag ($entry->getElementsByTagName('name'))
      {
        $appname = $tag->text;
      }

      foreach $tag ($entry->getElementsByTagName('target'))
      {
        $apptarget = $tag->text;
      }
    }
    print $appname.":".$apptarget."\n";
  }
  $twig->purge;
  return 1;
}

############################
# print xml in text format #
############################
sub print_txt
{
  my $entry; my $nchild; my $child = $_[0];
  my $identtmp;

  if ($child->children_count == 0)
  {
    if ($child->tag eq "#PCDATA")
    {
      print $ident."|- ".$child->parent->tag." = ".$child->text."\n";
    }
    else
    {
      print $ident."|- ".$child->tag." = ".$child->text."\n";
    }
  }
  else
  {
    if ($child->children_count == 1)
    {
      for $nchild ($child->children)
      {
        if ($nchild->tag ne "#PCDATA")
        {
          print $ident."+ ".$child->tag."\n";
          $identtmp = $ident;
          $ident .= "  ";
        }
      }
    }
    else
    {
      print $ident."+ ".$child->tag."\n";

      $identtmp = $ident;
      $ident .= "  ";
    }

    for $entry ($child->children)
    {
      print_txt($entry);
    }

    if (not empty($identtmp))
    {
      $ident = $identtmp;
    }
  }
}

####################
# XML to  txt tags #
####################
sub xml2txt
{
  my($twig, $elt)= @_;
  my $entry; my $child;

  print_txt($elt);
}

############################
# print xml in html format #
############################
sub print_html
{
  my $entry; my $nchild; my $child = $_[0];

  if ($child->children_count == 0)
  {
    if ($child->tag eq "#PCDATA")
    {
      print "<LI>".$child->parent->tag." = ".$child->text."</LI>\n";
    }
    else
    {
      print "<LI>".$child->tag." = ".$child->text."</LI>\n";
    }
  }
  else
  {
    if ($child->children_count == 1)
    {
      for $nchild ($child->children)
      {
        if ($nchild->tag ne "#PCDATA")
        {
          print "<LI>".$child->tag."</LI>\n";
          print "<UL>\n";
        }
      }
    }
    else
    {
      print "<LI>".$child->tag."</LI>\n";
      print "<UL>\n";
    }

    for $entry ($child->children)
    {
      print_html($entry);
    }

    if ($child->children_count > 1)
    {
      print "</UL>\n";
    }
    elsif ($child->children_count == 1)
    {
      for $nchild ($child->children)
      {
        if ($nchild->tag ne "#PCDATA")
        {
          print "</UL>\n";
        }
      }
    }
  }
}

#####################
# XML to  html tags #
#####################
sub xml2html
{
  my($twig, $elt)= @_;
  my $entry; my $child;

  print "<HTML>\n<HEAD>\n<STYLE>\n</STYLE>\n<TITLE></TITLE>\n</HEAD>\n<BODY>\n";
  print "<UL>\n";
  print_html($elt);
  print "</UL>\n";
  print "</BODY>\n</HTML>\n";
}

##################################
# Process command line arguments #
##################################
if ( $#ARGV < 1 )
{
  print "Usage: ".basename($0)." {WebLogic_Config_file.xml} [OBJECT] [OPTION].\n\n";
  print " Objects\n\n";
  print "  all                    : List all objects present in the provided WebLogic configuration file.\n";
  print "  server                 : List all servers present in the provided WebLogic configuration file.\n";
  print "  cluster                : List all clusters present in the provided WebLogic configuration file.\n";
  print "  machine                : List all machines present in the provided WebLogic configuration file.\n";
  print "  application (war/ear)  : List all applications present in the provided WebLogic configuration file.\n\n";
  print " Options\n\n";
  print "  -listenport [server]   : List admin server name and listenig port. If object [server] is specified, will list listening ports for all servers\n";
  print "  -members all           : List servers and their related clusters and machines.\n";
  print "  -apptargets            : List all applications and targets present in the provided WebLogic configuration file.\n";
  print "  -xml2txt               : Display WebLogic configuration file in plain text.\n";
  print "  -xml2html              : Display WebLogic configuration file in html format.\n";
  print "\n";
  exit 1;
}
elsif ( -e "$ARGV[0]" )
{
  $config_file="$ARGV[0]";
}
else
{
  print "File ".$ARGV[0]." not found.\n";
  exit 1;
}

foreach $arg (@ARGV)
{
  if ("$arg" eq "$config_file")
  {
    next;
  }
  elsif (("$arg" eq "cluster") || ("$arg" eq "server") || ("$arg" eq "machine") || ("$arg" eq "all") || ("$arg" eq "application"))
  {
    if (("$object" eq "EMPTY"))
    {
      $object = $arg;
    }
    else
    {
      print "Select only one object type (all/machine/cluster/server/application).\n";
      exit 1;
    }

  }
  elsif (("$arg" eq "-xml2html") || ("$arg" eq "-xml2txt") || ("$arg" eq "-members") || ("$arg" eq "-listenport") || ("$arg" eq "-apptargets"))
  {
    $option=$arg;
  }
  elsif ("$arg" eq "$config_file")
  {
    next;
  }
  else
  {
    print "Unrecognized option or object $arg.\n";
    exit 1;
  }
}

# Check for configuration file version
check_wl_version();

# Start parsing xml
if (("$object" eq "cluster") && ("$option" eq "-members"))
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(twig_roots => {"Server" => 1}, TwigHandlers => {"Server" => \&print_cluster_members});
  }
  else
  {	
    $twig = XML::Twig->new(twig_roots => {"server" => 1}, TwigHandlers => {"server" => \&print_cluster_members});
  }
}
elsif (("$object" eq "machine") && ("$option" eq "-members"))
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(twig_roots => {"Server" => 1}, TwigHandlers => {"Server" => \&print_machine_members});
  }
  else
  {
    $twig = XML::Twig->new(twig_roots => {"server" => 1}, TwigHandlers => {"server" => \&print_machine_members});
  }
}
elsif (("$object" eq "all") && ("$option" eq "-members"))
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(twig_roots => {"Server" => 1}, TwigHandlers => {"Server" => \&print_server_members});
  }
  else
  {
    $twig = XML::Twig->new(twig_roots => {"server" => 1}, TwigHandlers => {"server" => \&print_server_members});
  }
}
elsif ("$object" eq "all")
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(TwigHandlers => {'Machine' => \&print_name_with_type, 'Cluster' => \&print_name_with_type, 'Server' => \&print_name_with_type, 'Application/WebAppComponent' => \&print_name_with_type});
  }
  else
  {
    $twig = XML::Twig->new(TwigHandlers => {"machine/name" => \&print_name_with_type, "server/name" => \&print_name_with_type, "cluster/name" => \&print_name_with_type, "domain/app-deployment" => \&print_name_with_type});
  }
}
elsif (("$option" eq "EMPTY") && ("$object" ne "EMPTY"))
{
  if ($wlsversion == 8)
  {
    if ($object eq "application")
    {
      $twig = XML::Twig->new(TwigHandlers => {"Application/WebAppComponent" => \&print_app_name});
    }
    else
    {
      $object=uc(substr($object, 0, 1)).substr($object, 1);
      $twig = XML::Twig->new(twig_roots => {"$object" => 1}, TwigHandlers => {"$object" => \&print_name});
    }
  }
  else
  {
    if ($object eq "application")
    {
      $twig = XML::Twig->new(twig_roots => {"domain/app-deployment" => 1}, TwigHandlers => {"domain/app-deployment" => \&print_app_name});
    }
    else
    {
      $twig = XML::Twig->new(twig_roots => {"$object/name" => 1}, TwigHandlers => {"$object/name" => \&print_name});
    }
  }
}
elsif (("$option" eq "-listenport") && ("$object" ne "server"))
{
  $twig = XML::Twig->new(TwigHandlers => {"domain/admin-server-name" => \&get_admin_name});
  $twig->parsefile("$config_file");
  $twig = XML::Twig->new(TwigHandlers => {"server/listen-port" => \&print_listen_port});
}
elsif (("$option" eq "-listenport") && ("$object" eq "server"))
{
  $twig = XML::Twig->new(TwigHandlers => {"server/listen-port" => \&print_listen_port});
}
elsif ("$option" eq "-apptargets")
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(TwigHandlers => {"Application/WebAppComponent" => \&print_app_targets});
  }
  else
  {
    $twig = XML::Twig->new(TwigHandlers => {"domain/app-deployment" => \&print_app_targets});
  }
}
elsif ("$option" eq "-xml2txt")
{
  if ($wlsversion == 8)
  {
    $twig = XML::Twig->new(TwigHandlers => {"Domain" => \&xml2txt});
  }
  else
  {
    $twig = XML::Twig->new(TwigHandlers => {"domain" => \&xml2txt});
  }
}
elsif ("$option" eq "-xml2html")
{
  $twig = XML::Twig->new(TwigHandlers => {"domain" => \&xml2html});
}
else
{
  exit 0;
}

$twig->parsefile("$config_file");

exit 0;
