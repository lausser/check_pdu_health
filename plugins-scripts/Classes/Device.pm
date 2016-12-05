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
        bless $self, 'Classes::APC::Powermib::ATS';
        $self->debug('using Classes::APC::Powermib::ATS');
      } elsif ($self->implements_mib('PDU2-MIB')) {
        bless $self, 'Classes::Raritan';
        $self->debug('using Classes::Raritan');
      } elsif ($self->implements_mib('Sentry3-MIB')) {
        bless $self, 'Classes::Sentry3';
        $self->debug('using Classes::Sentry3');
      } elsif ($self->implements_mib('Sentry4-MIB')) {
        bless $self, 'Classes::Sentry4';
        $self->debug('using Classes::Sentry4');
      } elsif ($self->implements_mib('DAMOCLES-MIB')) {
        bless $self, 'Classes::HWG::Damocles';
        $self->debug('using Classes::HWG::Damocles');
      } elsif ($self->implements_mib('LIEBERT-GP-PDU-MIB')) {
        bless $self, 'Classes::Liebert';
        $self->debug('using Classes::Liebert');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          bless $self, $class;
          $self->debug('using '.$class);
        } else {
          bless $self, 'Classes::Generic';
          $self->debug('using Classes::Generic');
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

