package CheckPduHealth;
use strict;
no warnings qw(once);

sub run_plugin {
  my $plugin_class = (caller(0))[0]."::Device";
  if ( ! grep /BEGIN/, keys %Monitoring::GLPlugin::) {
    eval {
      require Monitoring::GLPlugin;
      require Monitoring::GLPlugin::SNMP;
    };
    if ($@) {
      printf "UNKNOWN - module Monitoring::GLPlugin was not found. Either build a standalone version of this plugin or set PERL5LIB\n";
      printf "%s\n", $@;
      exit 3;
    }
  }
  my $plugin = $plugin_class->new(
      shortname => '',
      usage => 'Usage: %s [ -v|--verbose ] [ -t <timeout> ] '.
          '--mode <what-to-do> '.
          '--hostname <network-component> --community <snmp-community>'.
          '  ...]',
      version => '$Revision: #PACKAGE_VERSION# $',
      blurb => 'This plugin checks various parameters of power distribution units ',
      url => 'http://labs.consol.de/nagios/check_pdu_health',
      timeout => 60,
  );
  
  $plugin->add_mode(
      internal => 'device::hardware::health',
      spec => 'hardware-health',
      alias => undef,
      help => 'Check the status of environmental equipment (fans, temperatures, power, selftests)',
  );
  $plugin->add_mode(
      internal => 'device::power::health',
      spec => 'power-health',
      alias => ['battery-health'],
      help => 'Check the status of power in/out',
  );
  $plugin->add_snmp_modes();
  $plugin->add_snmp_args();
  $plugin->add_default_args();
  
  $plugin->getopts();
  $plugin->classify();
  $plugin->validate_args();
  
  if (! $plugin->check_messages()) {
    $plugin->init();
    if (! $plugin->check_messages()) {
      $plugin->add_ok($plugin->get_summary())
          if $plugin->get_summary();
      $plugin->add_ok($plugin->get_extendedinfo(" "))
          if $plugin->get_extendedinfo();
    }
  }
  my ($code, $message) = $plugin->opts->multiline ?
      $plugin->check_messages(join => "\n", join_all => ', ') :
      $plugin->check_messages(join => ', ', join_all => ', ');
  $message .= sprintf "\n%s\n", $plugin->get_info("\n")
      if $plugin->opts->verbose >= 1;
  
  $plugin->nagios_exit($code, $message);
}

1;

join('', map { ucfirst } split(/_/, (split(/\//, (split ' ', $0 // '')[0]))[-1]))->run_plugin();
