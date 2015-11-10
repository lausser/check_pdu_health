package Classes::Sentry3::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('Sentry3-MIB', [
    ['envmons', 'envMonTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::EnvMon'],
    #['temphumidsensors', 'tempHumidSensorTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::Sensor'],
    ['temphumidsensors', 'tempHumidSensorTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::Sensor', sub { my $o = shift; $o->{tempHumidSensorStatus} ne 'notFound'}],
    ['contacts', 'contactClosureTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::Closure'],

    ['branches', 'branchTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['towers', 'towerTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['infeeds', 'infeedTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outlets', 'outletTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  
}

sub check {
  my $self = shift;
  foreach (@{$self->{temphumidsensors}}) {
    $_->check();
  }
}

package Classes::Sentry3::Components::EnvironmentalSubsystem::EnvMon;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{sensors} = [];
}

package Classes::Sentry3::Components::EnvironmentalSubsystem::Sensor;
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
