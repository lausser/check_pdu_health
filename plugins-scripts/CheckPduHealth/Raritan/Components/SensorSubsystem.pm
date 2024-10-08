package CheckPduHealth::Raritan::Components::ExternalSensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('PDU2-MIB', [
    ['extsensconfigs', 'externalSensorConfigurationTable', 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ExternalSensor'],
    ['extsensmeasurements', 'externalSensorMeasurementsTable', 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ExternalSensorMeasurement'],
  ]);
  foreach my $extmeasure (@{$self->{extsensmeasurements}}) {
    # pduId, sensorID
    foreach my $extconfig (@{$self->{extsensconfigs}}) {
      # pduId, sensorID
      if ($extmeasure->{flat_indices} eq $extconfig->{flat_indices}) {
        foreach (grep /measurements/, keys %{$extmeasure}) {
          $extconfig->{$_} = $extmeasure->{$_};
        }
        $extconfig->shorten();
      }
    }
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{extsensconfigs}}) {
    $_->check();
  }
}

package CheckPduHealth::Raritan::Components::InletSensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('PDU2-MIB', [
    ['inlsensconfigs', 'inletSensorConfigurationTable', 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletSensor'],
    ['inlsensmeasurements', 'inletSensorMeasurementsTable', 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletSensorMeasurement'],
  ]);
  foreach my $inlmeasure (@{$self->{inlsensmeasurements}}) {
    # pduId, sensorID
    foreach my $inlconfig (@{$self->{inlsensconfigs}}) {
      # pduId, sensorID
      if ($inlmeasure->{flat_indices} eq $inlconfig->{flat_indices}) {
        foreach (grep /measurements/, keys %{$inlmeasure}) {
          $inlconfig->{$_} = $inlmeasure->{$_};
        }
        $inlconfig->shorten();
      }
    }
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{inlsensconfigs}}) {
    $_->check();
  }
}


package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::Sensor);

sub check {
  my $self = shift;
  if (! exists $self->{perflabel_prefix}) {
    $self->{perflabel_prefix} = "sensor_";
  }
  if ($self->{SensorIsAvailable} eq 'true') {
    $self->add_info(sprintf '%s sensor %s is %s',
        $self->{SensorType}, $self->{SensorName}, $self->{SensorState});
    $self->add_info(sprintf '%s sensor %s shows %s%s',
        $self->{SensorType}, $self->{SensorName},
        $self->{SensorValue}, $self->{SensorUnits});
    $self->make_thresholds();
    my $level = $self->check_thresholds(
        metric => $self->{perflabel_prefix}.$self->{SensorName},
        value => $self->{SensorValue},
    );
    if ($level || $self->{SensorState} =~ /(below|above)/) {
      $self->add_message($level, sprintf '%s is out of range (%s%s)',
          $self->{SensorName}, $self->{SensorValue},
          $self->{SensorUnits});
    } else {
      $self->add_ok();
    }
    $self->add_perfdata(label => $self->{perflabel_prefix}.$self->{SensorName},
        value => $self->{SensorValue},
        thresholds => 1,
        uom => $self->{SensorUnits} eq '%' ? '%' : undef,
    );
  }
}

sub make_thresholds {
  my $self = shift;
  # 0 => 'lowerCritical', 1 => 'lowerWarning', 2 => 'upperWarning', 3 => 'upperCritical',
  my $EnabledThresholds = $self->{SensorEnabledThresholds};
  if ($EnabledThresholds =~ /^0x(\w)0/) {
    $EnabledThresholds = hex $1;
  } elsif ($EnabledThresholds =~ /^(\w)0/) {
    $EnabledThresholds = hex $1;
  } else {
    $EnabledThresholds = hex unpack('H1', $EnabledThresholds);
  }
  #$EnabledThresholds >>= 8;
  $EnabledThresholds &= 0xf;
  # 0000 nix w
  # 0010 lw
  # 0100 uw
  # 0110 luw
  $self->{warning} = undef;
  if ($EnabledThresholds & 0x1a == 0x1a) {
    $self->{warning} = sprintf "%.2f:%.2f",
        $self->{SensorLowerWarningThreshold},
        $self->{SensorUpperWarningThreshold};
  } elsif ($EnabledThresholds & 0x10 == 0x10) {
    $self->{warning} = sprintf "%.2f",
        $self->{SensorUpperWarningThreshold};
  } elsif ($EnabledThresholds & 0x0a == 0x0a) {
    $self->{warning} = sprintf "%.2f:",
        $self->{SensorLowerWarningThreshold};
  }
  # 1000 uc
  # 0001 lc
  # 1001 ulc
  $self->{critical} = undef;
  if ($EnabledThresholds & 0xa1 == 0xa1) {
    $self->{critical} = sprintf "%.2f:%.2f",
        $self->{SensorLowerCriticalThreshold},
        $self->{SensorUpperCriticalThreshold};
  } elsif ($EnabledThresholds & 0xa0 == 0xa0) {
    $self->{critical} = sprintf "%.2f",
        $self->{SensorUpperCriticalThreshold};
  } elsif ($EnabledThresholds & 0x01 == 0x01) {
    $self->{critical} = sprintf "%.2f:",
        $self->{SensorLowerCriticalThreshold};
  }
  $self->set_thresholds(metric => 'sensor_'.$self->{SensorName},
      warning => $self->{warning}, critical => $self->{critical});
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  if (! exists $self->{perflabel_prefix}) {
    $self->{perflabel_prefix} = "sensor_";
  }
  if ($self->{SensorIsAvailable} eq 'true') {
    if (defined $self->{SensorValue} =~ /^\d+$/) {
      $self->add_info(sprintf '%s sensor %s is %s (%.2f %s)',
          $self->{SensorType}, $self->{SensorName}, $self->{SensorState},
          $self->{SensorValue}, $self->{SensorUnits});
      my $label = sprintf '%s%s%s', $self->{perflabel_prefix},
          $self->{SensorName},
          $self->{SensorType} eq 'inlet' && $self->{SensorUnits} ?
          '_'.$self->{SensorUnits} : '';
      $self->add_perfdata(label => $label,
          value => $self->{SensorValue},
          thresholds => 0,
          uom => $self->{SensorUnits} eq '%' ? '%' : undef,
      );
    } else {
      $self->add_info(sprintf '%s sensor %s is %s',
          $self->{SensorType}, $self->{SensorName}, $self->{SensorState});
    }
    if (grep { $self->{SensorState} eq $_ } qw(normal closed on ok inSync)) {
      $self->add_ok();
    } else {
      $self->add_critical();
    }
  }
}

sub shorten {
  my $self = shift;
  foreach (keys %{$self}) {
    if ($_ =~ /^measurements(\w+)Sensor(.*)/) {
      $self->{'Sensor'.$2} = $self->{$_};
      delete $self->{$_};
    } elsif ($_ =~ /^(\w+)Sensor(.*)/) {
      $self->{'Sensor'.$2} = $self->{$_};
      delete $self->{$_};
    }
  }
  foreach (qw(SensorValue SensorLowerWarningThreshold
      SensorLowerCriticalThreshold SensorUpperWarningThreshold
      SensorUpperCriticalThreshold)) {
    if ($self->{$_} =~ /^[\d\.]+$/ &&
        $self->{SensorDecimalDigits} =~ /^[\d\.]+$/) {
      $self->{$_} /=
          10 ** $self->{SensorDecimalDigits};
    }
  }
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ExternalSensorMeasurement;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ExternalSensor;
our @ISA = qw(CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::Sensor Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{perflabel_prefix} = "";
  if ($self->{externalSensorType} eq 'temperature') {
    bless $self, 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::TemperatureSensor';
    $self->finish2();
  } elsif ($self->{externalSensorType} eq 'humidity') {
    bless $self, 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::HumiditySensor';
    $self->finish2();
  } elsif ($self->{externalSensorType} eq 'onOff') {
    bless $self, 'CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OnOffSensor';
    $self->finish2();
  }
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InternalSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::RmsCurrentSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::PeakCurrentSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::UnbalancedCurrentSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::RmsVoltageSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ActivePowerSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ApparentPowerSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::PowerFactorSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ActiveEnergySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ApparentEnergySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::TemperatureSensor;
our @ISA = qw(CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor Monitoring::GLPlugin::SNMP::TableItem);
use strict;
sub finish2 {
  my $self = shift;
  $self->{perflabel_prefix} = "temp_";
  $self->{externalSensorUnits} = 'C' if $self->{externalSensorUnits} eq 'degreeC';
  $self->{externalSensorUnits} = 'F' if $self->{externalSensorUnits} eq 'degreeF';
  $self->{externalSensorUnits} = '' if $self->{externalSensorUnits} eq 'degrees';
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::HumiditySensor;
our @ISA = qw(CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish2 {
  my $self = shift;
  $self->{perflabel_prefix} = "hum_";
  $self->{externalSensorUnits} = '%';
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::AirFlowSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::AirPressureSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OnOffSensor;
our @ISA = qw(CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish2 {
  my $self = shift;
  $self->{perflabel_prefix} = "onoff_";
  $self->{externalSensorUnits} = '';
}

sub check {
  my $self = shift;
  if ($self->{SensorIsAvailable} eq 'true') {
    $self->add_info(sprintf '%s sensor %s is %s',
        $self->{SensorType}, $self->{SensorName}, $self->{SensorState});
    if (grep { $self->{SensorState} eq $_ } qw(normal closed on ok inSync)) {
      $self->add_ok();
    } else {
      $self->add_critical();
    }
  }
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::TripSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::VibrationSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::WaterDetectionSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish2 {
  my $self = shift;
  $self->{externalSensorUnits} = '';
}

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::SmokeDetectionSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::BinarySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ContactSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::FanSpeedSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::SurgeProtectorStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::FrequencySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::PhaseAngleSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OtherSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::NoneSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::PowerQualitySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OverloadStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OverheatStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ScrOpenStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ScrShortStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::FanStatusSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletPhaseSyncAngleSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletPhaseSyncSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::OperatingStateSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::ActiveInletSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletSensor;
our @ISA = qw(CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::Sensor Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{inletSensorType} = 'inlet';
  $self->{inletSensorName} = $self->{flat_indices};
}


package CheckPduHealth::Raritan::Components::EnvironmentalSubsystem::InletSensorMeasurement;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


