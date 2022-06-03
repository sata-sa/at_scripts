#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use utf8;
use DateTime;
use MIME::Base64;
use Term::ANSIColor;
use Scalar::MoreUtils qw(empty);
#use SOAP::Lite 'trace', 'debug';
use SOAP::Lite;

########################
# Variable declaration #
########################
#
# WSDL Address: http://swnagcdev.ritta.local:7001/infoTaxonomia.asmx?wsdl
#
my $endpoint = "http://swnagcdev.ritta.local:7001/infoTaxonomia.asmx";
my $object;
my $option;

########################
# Function declaration #
########################
sub usage
{
  print "Usage: $0 [OPTION] [APPLICATION NAME]\n\n Options\n\n";
  print "  -fqdn [Application Name]       \n";
  print "  -altfqdn [Application Name]    \n";
  print "  -macrosistema [Application Name] \n";
  print "  -sistema [Application Name] \n";
  print "  -subsistema [Application Name] \n";
  print "  -sigla [Application Name]      \n";
  print "  -listall \n";
  print "\n";
  exit;
}

sub get_application_info
{
  my $soap;
  my $method;
  my @parameters;
  my $result;
  my %appinfo;

  if ($_[1] eq $object)
  {
    my $appname = $object;

    # Define method parameters
    $method = SOAP::Data->name('tem:getDadosAplicacaoBySigla')->attr({'xmlns:tem' => 'http://tempuri.org/'});
    @parameters = (SOAP::Data->name('tem:sigla' => $appname)->type(''));

    # Start SOAP request
    $soap = SOAP::Lite->new(proxy => $endpoint);
    $soap->on_action(sub{sprintf '"%sgetDadosAplicacaoBySigla"', @_});
    $result = $soap->call($method => @parameters);
    die $result->faultstring if ($result->fault);

    if (!empty(${$result->result}{'aplicacao'}))
    {
      %appinfo = %{${$result->result}{'aplicacao'}};
    }
    else
    {
      print "No application $appname found in taxonomy database\n";
      exit 0;
    }
  }
  else
  {
    die "No application name defined.\n";
  }

  if (empty ($_[0]))
  {
    print "Sigla         : $appinfo{'sigla'}\n";
    print "Macrosistema  : $appinfo{'macrosistema'}\n";
    print "Sistema       : $appinfo{'sistema'}\n";
    print "Subsistema    : $appinfo{'subsistema'}\n";
    print "FQDN          : $appinfo{'fqdn'}\n";
    print "Alt FQDN      : $appinfo{'altfqdn'}\n";
  }
  elsif ($_[0] eq "-fqdn")
  {
    print "$appinfo{'fqdn'}\n";
  }
  elsif ($_[0] eq "-altfqdn")
  {
    print "$appinfo{'altfqdn'}\n";
  }
  elsif ($_[0] eq "-sigla")
  {
    print "$appinfo{'sigla'}\n";
  }
  elsif ($_[0] eq "-subsistema")
  {
    print "$appinfo{'subsistema'}\n";
  }
  elsif ($_[0] eq "-sistema")
  {
    print "$appinfo{'sistema'}\n";
  }
  elsif ($_[0] eq "-macrosistema")
  {
    print "$appinfo{'macrosistema'}\n";
  }
}

sub get_all_applications_info
{
  my $soap;
  my $result;
  my $method;
  my %appinfo;
  my @applist;
  my $entry;
  my $key;

  # Define method parameters
  $method = SOAP::Data->name('tem:getTodasAplicacoes')->attr({'xmlns:tem' => 'http://tempuri.org/'});

  # Start SOAP request
  $soap = SOAP::Lite->new(proxy => $endpoint);
  $soap->on_action(sub{sprintf '"%sgetTodasAplicacoes"', @_});
  $result = $soap->call($method);
  die $result->faultstring if ($result->fault);
  @applist = %{${$result->result}{'aplicacoes'}};

  foreach $entry (@{$applist[1]})
  {
    print "Sigla         : $entry->{'sigla'}\n";
    print "Macrosistema  : $entry->{'macrosistema'}\n";
    print "Sistema       : $entry->{'sistema'}\n";
    print "Subsistema    : $entry->{'subsistema'}\n";
    print "FQDN          : $entry->{'fqdn'}\n";
    print "Alt FQDN      : $entry->{'altfqdn'}\n\n";
  }
}

########################
# Main execution block #
########################
binmode(STDOUT, ":utf8");

if ($#ARGV == -1)
{
  usage;
}
else
{
  foreach (0 .. $#ARGV)
  {
    if (($ARGV[$_] eq "-listall"))
    {
      get_all_applications_info;
      exit 0;
    }
    elsif (($ARGV[$_] eq "-macrosistema") or ($ARGV[$_] eq "-sistema") or ($ARGV[$_] eq "-listall") or ($ARGV[$_] eq "-fqdn") or ($ARGV[$_] eq "-altfqdn") or ($ARGV[$_] eq "-sigla") or ($ARGV[$_] eq "-subsistema"))
    {
      $option = $ARGV[$_];
    }
    else
    {
      $object = $ARGV[$_];
    }
  }

  if (not empty($object))
  {
    get_application_info($option, $object);
    exit 0;
  }
}
