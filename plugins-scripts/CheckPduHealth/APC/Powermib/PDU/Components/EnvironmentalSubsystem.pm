package CheckPduHealth::APC::Powermib::PDU::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  # Fetch device status for power supply checks
  $self->get_snmp_tables('PowerNet-MIB', [
    ['device_status', 'rPDU2DeviceStatusTable', 'CheckPduHealth::APC::Powermib::PDU::Components::EnvironmentalSubsystem::DeviceStatus'],
    ['device_config', 'rPDU2DeviceConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);

  # Merge device config into device status
  $self->merge_tables_with_code("device_status", "device_config", sub {
    my($sta, $cfg) = @_;
    return ($sta->{rPDU2DeviceStatusModule} == $cfg->{rPDU2DeviceConfigModule}) ? 1 : 0;
  });

  # Fetch temperature/humidity sensors
  $self->get_snmp_tables('PowerNet-MIB', [
    ['temp_humidity_sensors', 'rPDU2SensorTempHumidityStatusTable', 'CheckPduHealth::APC::Powermib::PDU::Components::EnvironmentalSubsystem::TempHumiditySensor'],
    ['temp_humidity_config', 'rPDU2SensorTempHumidityConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);

  # Merge sensor config into sensor status
  $self->merge_tables_with_code("temp_humidity_sensors", "temp_humidity_config", sub {
    my($sta, $cfg) = @_;
    return ($sta->{rPDU2SensorTempHumidityStatusIndex} == $cfg->{rPDU2SensorTempHumidityConfigIndex}) ? 1 : 0;
  });

  # Store environmental subsystem info
  my $sensor_count = scalar(@{$self->{temp_humidity_sensors}}) if defined $self->{temp_humidity_sensors};
  $sensor_count ||= 0;
  $self->{_subtree_used} = 'rPDU2';
  $self->{_sensor_count} = $sensor_count;
}

sub check {
  my $self = shift;

  # Log diagnostic info about which subtree and data were found (internal only)
  if (defined $self->{_subtree_used}) {
    $self->debug(sprintf("OID subtree: %s (%d sensors)",
      $self->{_subtree_used},
      $self->{_sensor_count} // 0
    ));
  }

  # Check device status (power supplies) and sensors
  $self->SUPER::check();

  # If no specific messages were generated, add informative summary
  if (!$self->check_messages()) {
    if ($self->{_sensor_count} == 0) {
      $self->add_ok('power supplies nominal, no environmental sensors installed');
    } else {
      $self->add_ok('power supplies nominal, all sensors within limits');
    }
  }

  $self->reduce_messages_short();
}



package CheckPduHealth::APC::Powermib::PDU::Components::EnvironmentalSubsystem::DeviceStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;

  # Power supply alarm
  $self->add_info(sprintf("power supply alarm: %s", $self->{rPDU2DeviceStatusPowerSupplyAlarm} // 'unknown'));
  if ($self->{rPDU2DeviceStatusPowerSupplyAlarm} eq 'active') {
    $self->add_critical();
  } elsif ($self->{rPDU2DeviceStatusPowerSupplyAlarm} eq 'normal') {
    $self->add_ok();
  } else {
    # unSupported or unknown
    $self->add_ok();
  }

  # Power supply 1 status
  $self->add_info(sprintf("power supply 1 status: %s", $self->{rPDU2DeviceStatusPowerSupply1Status} // 'unknown'));
  if ($self->{rPDU2DeviceStatusPowerSupply1Status} eq 'alarm' || $self->{rPDU2DeviceStatusPowerSupply1Status} eq 'failure') {
    $self->add_critical();
  } elsif ($self->{rPDU2DeviceStatusPowerSupply1Status} eq 'normal' || $self->{rPDU2DeviceStatusPowerSupply1Status} eq 'notInstalled') {
    $self->add_ok();
  } else {
    $self->add_ok();
  }

  # Power supply 2 status
  $self->add_info(sprintf("power supply 2 status: %s", $self->{rPDU2DeviceStatusPowerSupply2Status} // 'unknown'));
  if ($self->{rPDU2DeviceStatusPowerSupply2Status} eq 'alarm' || $self->{rPDU2DeviceStatusPowerSupply2Status} eq 'failure') {
    $self->add_critical();
  } elsif ($self->{rPDU2DeviceStatusPowerSupply2Status} eq 'normal' || $self->{rPDU2DeviceStatusPowerSupply2Status} eq 'notInstalled') {
    $self->add_ok();
  } else {
    $self->add_ok();
  }
}


package CheckPduHealth::APC::Powermib::PDU::Components::EnvironmentalSubsystem::TempHumiditySensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# Helper to build Nagios threshold range strings from partial threshold sets
# Returns (warning_range, critical_range) based on available low/high/min/max
# Examples: ("low:high", "min:max"), ("low:", "~:max"), (undef, "~:max"), etc.
sub _build_threshold_range {
  my ($low, $high, $min, $max) = @_;

  # Determine warning range (low:high)
  my $warn_range;
  if (defined $low || defined $high) {
    if (defined $low && defined $high) {
      $warn_range = "$low:$high";
    } elsif (defined $low) {
      $warn_range = "$low:";
    } else {
      $warn_range = "~:$high";
    }
  }

  # Determine critical range (min:max)
  my $crit_range;
  if (defined $min || defined $max) {
    if (defined $min && defined $max) {
      $crit_range = "$min:$max";
    } elsif (defined $min) {
      $crit_range = "$min:";
    } else {
      $crit_range = "~:$max";
    }
  }

  return ($warn_range, $crit_range);
}

sub finish {
  my $self = shift;
  # Scale temperature values (tenths of degree)
  $self->{rPDU2SensorTempHumidityStatusTempC} = $self->{rPDU2SensorTempHumidityStatusTempC} / 10
    if defined $self->{rPDU2SensorTempHumidityStatusTempC};
  $self->{rPDU2SensorTempHumidityStatusTempF} = $self->{rPDU2SensorTempHumidityStatusTempF} / 10
    if defined $self->{rPDU2SensorTempHumidityStatusTempF};
  # Humidity is already in whole percentages, no scaling needed
  $self->{sensor_index} = $self->{flat_indices};
  $self->{sensor_index} =~ s/\..*$//;
}

sub check {
  my $self = shift;
  my $sensor_idx = $self->{sensor_index};

  # Always emit sensor status info
  $self->add_info(sprintf("sensor %d: temp %.1f°C, humidity %d%%",
    $sensor_idx,
    $self->{rPDU2SensorTempHumidityStatusTempC} // 0,
    $self->{rPDU2SensorTempHumidityStatusRelativeHumidity} // 0));

  # Check temperature thresholds
  if (defined $self->{rPDU2SensorTempHumidityStatusTempC}) {
    my ($temp_warn, $temp_crit) = _build_threshold_range(
      $self->{rPDU2SensorTempHumidityConfigTempLowThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempHighThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempMinThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempMaxThreshC}
    );

    if (defined $temp_warn || defined $temp_crit) {
      $self->set_thresholds(
        metric => "temp_c",
        warning => $temp_warn,
        critical => $temp_crit
      );
      my $temp_level = $self->check_thresholds(
        metric => "temp_c",
        value => $self->{rPDU2SensorTempHumidityStatusTempC}
      );
      $self->add_message($temp_level, "") if $temp_level > 0;
    }
  }

  # Check humidity thresholds
  if (defined $self->{rPDU2SensorTempHumidityStatusRelativeHumidity}) {
    my ($hum_warn, $hum_crit) = _build_threshold_range(
      $self->{rPDU2SensorTempHumidityConfigHumidityLowThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityHighThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityMinThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityMaxThresh}
    );

    if (defined $hum_warn || defined $hum_crit) {
      $self->set_thresholds(
        metric => "humidity",
        warning => $hum_warn,
        critical => $hum_crit
      );
      my $hum_level = $self->check_thresholds(
        metric => "humidity",
        value => $self->{rPDU2SensorTempHumidityStatusRelativeHumidity}
      );
      $self->add_message($hum_level, "") if $hum_level > 0;
    }
  }

  # Emit perfdata with thresholds
  if (defined $self->{rPDU2SensorTempHumidityStatusTempC}) {
    my ($temp_warn, $temp_crit) = _build_threshold_range(
      $self->{rPDU2SensorTempHumidityConfigTempLowThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempHighThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempMinThreshC},
      $self->{rPDU2SensorTempHumidityConfigTempMaxThreshC}
    );

    $self->add_perfdata(
      label => "sensor${sensor_idx}_temp_c",
      value => $self->{rPDU2SensorTempHumidityStatusTempC},
      warning => $temp_warn,
      critical => $temp_crit
    );
  }

  if (defined $self->{rPDU2SensorTempHumidityStatusRelativeHumidity}) {
    my ($hum_warn, $hum_crit) = _build_threshold_range(
      $self->{rPDU2SensorTempHumidityConfigHumidityLowThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityHighThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityMinThresh},
      $self->{rPDU2SensorTempHumidityConfigHumidityMaxThresh}
    );

    $self->add_perfdata(
      label => "sensor${sensor_idx}_humidity",
      value => $self->{rPDU2SensorTempHumidityStatusRelativeHumidity},
      warning => $hum_warn,
      critical => $hum_crit
    );
  }
}

1;
