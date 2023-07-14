package Classes::Device;
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
        $self->rebless('Classes::APC::Powermib::ATS');
      } elsif ($self->implements_mib('PDU2-MIB')) {
        $self->rebless('Classes::Raritan');
      } elsif ($self->implements_mib('Sentry3-MIB')) {
        $self->rebless('Classes::Sentry3');
      } elsif ($self->implements_mib('Sentry4-MIB')) {
        $self->rebless('Classes::Sentry4');
      } elsif ($self->implements_mib('DAMOCLES-MIB')) {
        $self->rebless('Classes::HWG::Damocles');
      } elsif ($self->implements_mib('LIEBERT-GP-PDU-MIB')) {
        $self->rebless('Classes::Liebert');
      } elsif ($self->implements_mib('VERTIV-V5-MIB')) {
        $self->rebless('Classes::Vertiv::V5');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->rebless($class);
        } else {
          $self->rebless('Classes::Generic');
        }
      }
    }
  }
  return $self;
}


package Classes::Generic;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /.*/) {
    bless $self, 'Monitoring::GLPlugin::SNMP';
    $self->no_such_mode();
  }
}

