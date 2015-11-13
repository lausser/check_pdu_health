package Classes::Sentry4::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('Sentry4-MIB', qw(
      st4TempSensorScale st4TempSensorHysteresis));
  $self->get_snmp_tables('Sentry4-MIB', [
    ['unitconfigs', 'st4UnitConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['unitmonitors', 'st4UnitMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::Unit'],
    ['uniteventconfigs', 'st4UnitEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['tempsensorconfigs', 'st4TempSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['tempsensormonitors', 'st4TempSensorMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::TempSensor', sub { my $o = shift; $o->{st4TempSensorValue} != -41 && $o->{st4TempSensorStatus} ne 'notFound'}],
    ['tempsensoreventconfigs', 'st4TempSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['humidsensorconfigs', 'st4HumidSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['humidsensormonitors', 'st4HumidSensorMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::HumidSensor', sub { my $o = shift; $o->{st4HumidSensorValue} != -1 && $o->{st4HumidSensorStatus} ne 'notFound'}],
    ['humidsensoreventconfigs', 'st4HumidSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['watersensorconfigs', 'st4WaterSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['watersensormonitors', 'st4WaterSensorMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::WaterSensor'],
    ['watersensoreventconfigs', 'st4WaterSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['ccsensorconfigs', 'st4CcSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ccsensormonitors', 'st4CcSensorMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::CcSensor'],
    ['ccsensoreventconfigs', 'st4CcSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['adcsensorconfigs', 'st4DcSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['adcsensormonitors', 'st4DcSensorMonitorTable', 'Classes::Sentry4::Components::EnvironmentalSubsystem::AdcSensor'],
    ['adcsensoreventconfigs', 'st4DcSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  map {
      $_->{st4TempSensorScale} = $self->{st4TempSensorScale}
  } @{$self->{tempsensormonitors}};
  $self->merge(qw(unitmonitors unitconfigs uniteventconfigs));
  $self->merge(qw(tempsensormonitors tempsensorconfigs tempsensoreventconfigs));
  $self->merge(qw(humidsensormonitors humidsensorconfigs humidsensoreventconfigs));
  $self->merge(qw(watersensormonitors watersensorconfigs watersensoreventconfigs));
  $self->merge(qw(ccsensormonitors ccsensorconfigs ccsensoreventconfigs));
  $self->merge(qw(adcsensormonitors adcsensorconfigs adcsensoreventconfigs));
}

sub merge {
  my $self = shift;
  my($monitors, $configs, $eventconfigs) = @_;
  foreach my $sm (@{$self->{$monitors}}) {
    foreach my $sc (grep { $sm->{flat_indices} eq $_->{flat_indices} } @{$self->{$configs}}) {
      map { $sm->{$_} = $sc->{$_} } keys %{$sc};
    }
    foreach my $sec (grep { $sm->{flat_indices} eq $_->{flat_indices} } @{$self->{$eventconfigs}}) {
      map { $sm->{$_} = $sec->{$_} } keys %{$sec};
    }
  }
  delete $self->{$configs};
  delete $self->{$eventconfigs};
}


package Classes::Sentry4::Components::EnvironmentalSubsystem::Unit;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'unit %s status is %s',
      $self->{st4UnitName}, $self->{st4UnitStatus});
  if ($self->{st4UnitStatus} =~ /normal|disabled|purged|reading|settle/) {
    $self->add_ok();
  } elsif ($self->{st4UnitStatus} =~ /lowWarning|highWarning/) {
    $self->add_warning();
  } elsif ($self->{st4UnitStatus} =~ /readError|pwrError|breakerTripped|fuseBlown|lowAlarm|highAlarm|alarm|underLimit|overLimit|nvmFail|profileError|conflict/) {
    $self->add_critical();
  } elsif ($self->{st4UnitStatus} =~ /notFound|lost|noComm|/) {
    $self->add_unknown();
  }
}


package Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s status is %s',
      $self->{name}, $self->{status});
  if ($self->{status} =~ /normal|disabled|purged|reading|settle/) {
    $self->add_ok();
  } elsif ($self->{status} =~ /lowWarning|highWarning/) {
    $self->add_warning();
  } elsif ($self->{status} =~ /readError|pwrError|breakerTripped|fuseBlown|lowAlarm|highAlarm|alarm|underLimit|overLimit|nvmFail|profileError|conflict/) {
    $self->add_critical();
  } elsif ($self->{status} =~ /notFound|lost|noComm|/) {
    $self->add_unknown();
  }
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::TempSensor;
our @ISA = qw(Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor);

sub finish {
  my $self = shift;
  $self->{st4TempSensorValue} /= 10;
  # a st4TempSensorValue of -410 means: the temperature reading is invalid
  # thats why there is a filter sub != 41
  $self->{status} = $self->{st4TempSensorStatus};
}

sub check {
  my $self = shift;
  $self->{name} = $self->{st4TempSensorName} || 'temp_'.$self->{st4TempSensorID};
  $self->SUPER::check();
  $self->set_thresholds(
      metric => $self->{name},
      warning => $self->{st4TempSensorLowWarning}.':'.$self->{st4TempSensorHighWarning},
      critical => $self->{st4TempSensorLowAlarm}.':'.$self->{st4TempSensorHighAlarm},
  );
  $self->add_perfdata(label => $self->{name},
      value => $self->{st4TempSensorValue},
  );
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::HumidSensor;
our @ISA = qw(Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor);

sub finish {
  my $self = shift;
  $self->{status} = $self->{st4HumidSensorStatus};
}

sub check {
  my $self = shift;
  $self->{name} = $self->{st4HumidSensorName} || 'humid_'.$self->{st4HumidSensorID};
  $self->SUPER::check();
  $self->set_thresholds(
      metric => $self->{name},
      warning => $self->{st4HumidSensorLowWarning}.':'.$self->{st4HumidSensorHighWarning},
      critical => $self->{st4HumidSensorLowAlarm}.':'.$self->{st4HumidSensorHighAlarm},
  );
  $self->add_perfdata(label => $self->{name},
      value => $self->{st4HumidSensorValue},
      uom => '%',
  );
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::WaterSensor;
our @ISA = qw(Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor);

sub finish {
  my $self = shift;
  $self->{status} = $self->{st4WaterSensorStatus};
}

sub check {
  my $self = shift;
  $self->{name} = $self->{st4WaterSensorName} || 'water_'.$self->{st4WaterSensorID};
  $self->SUPER::check();
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::CcSensor;
our @ISA = qw(Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor);

sub finish {
  my $self = shift;
  $self->{status} = $self->{st4CcSensorStatus};
}

sub check {
  my $self = shift;
  $self->{name} = $self->{st4CcSensorName} || 'cc_'.$self->{st4CcSensorID};
  $self->SUPER::check();
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::AdcSensor;
our @ISA = qw(Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor);

sub finish {
  my $self = shift;
  $self->{status} = $self->{st4AdcSensorStatus};
}

sub check {
  my $self = shift;
  $self->{name} = $self->{st4AdcSensorName} || 'dc_'.$self->{st4AdcSensorID};
  $self->SUPER::check();
}

1;
