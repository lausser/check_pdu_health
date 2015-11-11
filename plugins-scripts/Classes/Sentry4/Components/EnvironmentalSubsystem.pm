package Classes::Sentry4::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('Sentry4-MIB', qw(
      st4TempSensorScale st4TempSensorHysteresis));
  $self->get_snmp_tables('Sentry4-MIB', [
    ['configs', 'st4UnitConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['monitors', 'st4UnitMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['eventconfigs', 'st4UnitEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['cordconfigs', 'st4InputCordConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['cordmonitor', 'st4InputCordMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['cordeventconfigs', 'st4InputCordEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['lineconfigs', 'st4LineConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['linemonitors', 'st4LineMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['lineeventconfigs', 'st4LineEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phaseconfigs', 'st4PhaseConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phasemonitors', 'st4PhaseMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phaseeventconfigs', 'st4PhaseEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['cpconfigs', 'st4OcpConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ocpmonitors', 'st4OcpMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ocpeventmon', 'st4OcpEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['branchconfigs', 'st4BranchConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['branchmonitors', 'st4BranchMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['brancheventconfigs', 'st4BranchEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outletconfigs', 'st4OutletConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outletmonitors', 'st4OutletMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outleteventconfigs', 'st4OutletEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outletcontrols', 'st4OutletControlTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['tempsensorconfigs', 'st4TempSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['tempsensormonitors', 'st4TempSensorMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['tempsensoreventconfigs', 'st4TempSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['humidsensorconfogs', 'st4HumidSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['humidsensormonitors', 'st4HumidSensorMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['humidsensorenetconifs', 'st4HumidSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['water', 'st4WaterSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['watermon', 'st4WaterSensorMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['waterevtcon', 'st4WaterSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ccsensorconfis', 'st4CcSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ccmonitors', 'st4CcSensorMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ccevtconfigs', 'st4CcSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['dcsensorconfis', 'st4DcSensorConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['dcmonitors', 'st4DcSensorMonitorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['dcevtconfigs', 'st4DcSensorEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  foreach my $tsc (@{$self->{tempsensorconfigs}}) {
    foreach my $tsm (grep { $tsc->{flat_indices} eq $_->{flat_indices} } @{$self->{tempsensormonitors}}) {
      map { $tsc->{$_} = $tsm->{$_} } keys %{$tsm};
    }
    foreach my $tsec (grep { $tsc->{flat_indices} eq $_->{flat_indices} } @{$self->{tempsensoreventconfigs}}) {
      map { $tsc->{$_} = $tsec->{$_} } keys %{$tsec};
    }
    $tsc->dump();
  }
  delete $self->{tempsensormonitors};
  delete $self->{tempsensoreventconfigs};
die;
}

sub check {
  my $self = shift;
  foreach (@{$self->{temphumidsensors}}) {
    $_->check();
  }
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::EnvMon;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{sensors} = [];
}

package Classes::Sentry4::Components::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{name} = $self->{tempHumidSensorName} || $self->{tempHumidSensorID};
  $self->{tempHumidSensorTempScale} ||= 'celsius';
  $self->{tempHumidSensorTempValue} /= 10 if $self->{tempHumidSensorTempValue};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'sensor %s status is %s',
      $self->{name}, $self->{tempHumidSensorStatus});
  if ($self->{tempHumidSensorStatus} eq 'lost') {
    $self->add_critical();
  } elsif ($self->{tempHumidSensorStatus} eq 'noComm') {
    $self->add_critical();
  } else {
    if ($self->{tempHumidSensorHumidValue} != -1) {
      $self->set_thresholds(
          metric => 'hum_'.$self->{name},
          warning => $self->{tempHumidSensorHumidLowThresh}.':',
          critical => $self->{tempHumidSensorHumidHighThresh},
      );
      $self->add_info(sprintf 'humidity sensor %s shows %s%%',
          $self->{name}, $self->{tempHumidSensorHumidValue});
      if ($self->{tempHumidSensorHumidStatus} eq 'normal') {
        $self->add_ok();
      } elsif ($self->{tempHumidSensorHumidStatus} eq 'humidLow') {
        $self->add_critical();
      } elsif ($self->{tempHumidSensorHumidStatus} eq 'humidHigh') {
        $self->add_critical();
      } else {
        $self->add_unknown();
      }
      $self->add_perfdata(label => 'hum_'.$self->{name},
          value => $self->{tempHumidSensorHumidValue},
          uom => '%',
      );
    } else {
      $self->add_unknown();
    }
    if ($self->{tempHumidSensorTempValue} != -1) {
      $self->set_thresholds(
          metric => 'temp_'.$self->{name},
          warning => $self->{tempHumidSensorTempLowThresh}.':',
          critical => $self->{tempHumidSensorTempHighThresh},
      );
      $self->add_info(sprintf 'temperature sensor %s shows %s %s',
          $self->{name}, $self->{tempHumidSensorTempValue},
          $self->{tempHumidSensorTempScale});
      if ($self->{tempHumidSensorTempStatus} eq 'normal') {
        $self->add_ok();
      } elsif ($self->{tempHumidSensorTempStatus} eq 'humidLow') {
        $self->add_critical();
      } elsif ($self->{tempHumidSensorTempStatus} eq 'humidHigh') {
        $self->add_critical();
      } else {
        $self->add_unknown();
      }
      $self->add_perfdata(label => 'temp_'.$self->{name},
          value => $self->{tempHumidSensorTempValue},
      );
    } else {
      $self->add_unknown();
    }
  }
}

1;
