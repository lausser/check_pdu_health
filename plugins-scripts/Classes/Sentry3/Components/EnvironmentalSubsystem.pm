package Classes::Sentry3::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('Sentry3-MIB', qw(
      towerStatus 
  ));
  $self->get_snmp_tables('Sentry3-MIB', [
    ['envmons', 'envMonTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::EnvMon'],
    ['temphumidsensors', 'tempHumidSensorTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::TempHumidSensor', sub { my $o = shift; $o->{tempHumidSensorStatus} ne 'notFound'}],
    ['contacts', 'contactClosureTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::Closure'],

    ###['branches', 'branchTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['towers', 'towerTable', 'Classes::Sentry3::Components::EnvironmentalSubsystem::Tower'],
    ###['infeeds', 'infeedTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ###['outlets', 'outletTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  
}


package Classes::Sentry3::Components::EnvironmentalSubsystem::Tower;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'tower %s status is %s',
      $self->{towerName}, $self->{towerStatus});
  if ($self->{towerStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{towerStatus} eq 'noComm') {
    $self->add_unknown();
  } else {
    $self->add_critical();
  }
}


package Classes::Sentry3::Components::EnvironmentalSubsystem::EnvMon;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{sensors} = [];
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s status is %s',
      $self->{envMonName}, $self->{envMonStatus});
  if ($self->{envMonStatus} ne 'normal') {
    $self->add_critical();
  }
  if ($self->{envMonWaterSensorName}) {
    $self->add_info(sprintf '%s status is %s',
        $self->{envMonWaterSensorName}, $self->{envMonWaterSensorStatus});
    if ($self->{envMonWaterSensorStatus} eq 'normal') {
      $self->add_ok();
    } elsif ($self->{envMonWaterSensorStatus} eq 'alarm') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  }
  if ($self->{envMonADCName}) {
    $self->add_info(sprintf '%s status is %s',
        $self->{envMonADCName}, $self->{envMonADCStatus});
    if ($self->{envMonADCStatus} eq 'normal') {
      $self->add_ok();
    } elsif ($self->{envMonADCStatus} eq 'alarm') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
    $self->add_perfdata(
        label => $self->{envMonADCName},
        critical => $self->{envMonADCLowThresh}.':'.$self->{envMonADCHighThresh},
    ) if $self->{envMonADCCount} >= 0;
  }
}


package Classes::Sentry3::Components::EnvironmentalSubsystem::Closure;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s status is %s',
      $self->{contactClosureName}, $self->{contactClosureStatus});
  if ($self->{contactClosureStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{contactClosureStatus} eq 'alarm') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
}

package Classes::Sentry3::Components::EnvironmentalSubsystem::TempHumidSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{tempHumidSensorTempScale} ||= 'celsius';
  $self->{tempHumidSensorTempValue} /= 10 if $self->{tempHumidSensorTempValue};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s status is %s',
      $self->{tempHumidSensorName}, $self->{tempHumidSensorStatus});
  if ($self->{tempHumidSensorStatus} eq 'lost') {
    $self->add_critical();
  } elsif ($self->{tempHumidSensorStatus} eq 'noComm') {
    $self->add_critical();
  } else {
    $self->add_info(sprintf 'humidity sensor %s shows %s%%',
        $self->{tempHumidSensorName}, $self->{tempHumidSensorHumidValue});
    $self->set_thresholds(
        metric => $self->{tempHumidSensorName},
        warning => $self->{tempHumidSensorHumidLowThresh}.':',
        critical => $self->{tempHumidSensorHumidHighThresh},
    );
    if ($self->{tempHumidSensorHumidStatus} eq 'normal') {
      $self->add_ok();
    } elsif ($self->{tempHumidSensorHumidStatus} eq 'humidLow') {
      $self->add_critical();
    } elsif ($self->{tempHumidSensorHumidStatus} eq 'humidHigh') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
    $self->add_perfdata(label => $self->{tempHumidSensorName},
        value => $self->{tempHumidSensorHumidValue},
        uom => '%',
    );
    $self->add_info(sprintf 'temperature sensor %s shows %s %s',
        $self->{tempHumidSensorName}, $self->{tempHumidSensorTempValue},
        $self->{tempHumidSensorTempScale});
    $self->set_thresholds(
        metric => $self->{tempHumidSensorName},
        warning => $self->{tempHumidSensorTempLowThresh}.':',
        critical => $self->{tempHumidSensorTempHighThresh},
    );
    if ($self->{tempHumidSensorTempStatus} eq 'normal') {
      $self->add_ok();
    } elsif ($self->{tempHumidSensorTempStatus} eq 'humidLow') {
      $self->add_critical();
    } elsif ($self->{tempHumidSensorTempStatus} eq 'humidHigh') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
    $self->add_perfdata(label => $self->{tempHumidSensorName},
        value => $self->{tempHumidSensorTempValue},
    );
  }
}

1;
