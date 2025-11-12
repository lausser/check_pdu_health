package CheckPduHealth::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP);
use strict;

sub classify {
  my $self = shift;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_unknown('either specify a hostname or a snmpwalk file');
  } else {
    $self->check_snmp_and_model();
    if (! $self->check_messages()) {
      if ($self->opts->verbose && $self->opts->verbose) {
        printf "I am a %s\n", $self->{productname};
      }
      if ($self->opts->mode =~ /^my-/) {
        $self->load_my_extension();
      } elsif ($self->get_snmp_object('PowerNet-MIB', 'atsIdentModelNumber') ||
          $self->get_snmp_object('PowerNet-MIB', 'atsIdentSerialNumber')) {
        $self->rebless('CheckPduHealth::APC::Powermib::ATS');
      } elsif ($self->implements_mib('PDU2-MIB')) {
        $self->rebless('CheckPduHealth::Raritan');
      } elsif ($self->implements_mib('Sentry3-MIB')) {
        $self->rebless('CheckPduHealth::Sentry3');
      } elsif ($self->implements_mib('Sentry4-MIB')) {
        $self->rebless('CheckPduHealth::Sentry4');
      } elsif ($self->implements_mib('DAMOCLES-MIB')) {
        $self->rebless('CheckPduHealth::HWG::Damocles');
      } elsif ($self->implements_mib('LIEBERT-GP-PDU-MIB')) {
        $self->rebless('CheckPduHealth::Liebert');
      } elsif ($self->implements_mib('VERTIV-V5-MIB')) {
        $self->rebless('CheckPduHealth::Vertiv::V5');
      } elsif ($self->implements_mib('AVOCENT-PM-MIB')) {
        $self->rebless('CheckPduHealth::AvocentPM');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->rebless($class);
        } else {
          $self->rebless('CheckPduHealth::Generic');
        }
      }
    }
  }
  $self->{generic_class} = "CheckPduHealth::Generic";
  return $self;
}


package CheckPduHealth::Generic;
our @ISA = qw(CheckPduHealth::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /.*/) {
    bless $self, 'Monitoring::GLPlugin::SNMP';
    $self->no_such_mode();
  }
}

