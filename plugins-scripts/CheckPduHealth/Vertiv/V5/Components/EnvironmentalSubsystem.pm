package CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('VERTIV-V5-MIB', qw(
      productTitle productVersion productFriendlyName
      deviceCount temperatureUnits
      productModelNumber productSerialNumber productPlatform
      productAlarmCount productWarnCount
      productManufacturer));
  $self->get_snmp_tables('VERTIV-V5-MIB', [
    ['t3hdsensors', 't3hdSensorTable', 'CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem::T3hdSensor'],
    ['a2dsensors', 'a2dSensorTable', 'CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem::A2dSensor'],
  ]);

}

sub check {
  my $self = shift;
  $self->SUPER::check();
  $self->add_info(sprintf '%s %s has %d warnings and %d critical alarms',
      $self->{productTitle}, $self->{productFriendlyName},
      $self->{productWarnCount}, $self->{productAlarmCount});
  if ($self->{productAlarmCount} > 0) {
    $self->add_critical();
  } elsif ($self->{productWarnCount} > 0) {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
}


package CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem::A2dSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  return if ! $self->{a2dSensorAvail};
  $self->add_info(sprintf "a2d sensor %s/%s reports %s%s",
      $self->{a2dSensorAnalogLabel},
      $self->{a2dSensorLabel},
      $self->{a2dSensorDisplayValue},
      ($self->{a2dSensorUnits} //= "")
  );
  if ($self->{a2dSensorMode} eq "door") {
    $self->add_message($self->{a2dSensorValue} == 1 ? 2 : 0);
  } elsif ($self->{a2dSensorMode} eq "wscFault") {
    $self->add_message($self->{a2dSensorValue} == 1 ? 2 : 0);
  } elsif ($self->{a2dSensorMode} eq "wscLeak") {
    $self->add_message($self->{a2dSensorValue} == 1 ? 2 : 0);
  } elsif ($self->{a2dSensorMode} eq "flood") {
    $self->add_message($self->{a2dSensorValue} == 1 ? 0 : 2);
  } elsif ($self->{a2dSensorMode} eq "customVoltage") {
    my $label = $self->{a2dSensorMode}."_".$self->{a2dSensorLabel}."_".$self->{flat_indices};
    $label = lc $label;
    my $range = "";
    if (defined $self->{a2dSensorMin}) {
      $range = $self->{a2dSensorMin}.":";
    }
    if (defined $self->{a2dSensorMin}) {
      $range .= $self->{a2dSensorMax};
    }
    $self->set_thresholds(
        metric => $label,
        warning => $range,
        critical => $range,
    );
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => $self->{a2dSensorValue},
    ));
    $self->add_perfdata(
        label => $label,
        value => $self->{a2dSensorValue},
    );
  } else {
    $self->annotate_info("UNSUPPORTED SENSOR TYPE!!");
    $self->add_ok();
  }
}


package CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem::T3hdSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{t3hdSensorIntTemp} /= 10;
  $self->{t3hdSensorIntDewPoint} /= 10;
  $self->{t3hdSensorExtATemp} /= 10;
  $self->{t3hdSensorExtBTemp} /= 10;
}

sub check {
  my ($self) = @_;
  my $label = "";
  $self->add_info(sprintf "t3hd sensor %s: %s temperature is %.2f, humidity is %.2f%%, dewpoint is %.2f%%",
      $self->{t3hdSensorLabel},
      $self->{t3hdSensorIntLabel},
      $self->{t3hdSensorIntTemp},
      $self->{t3hdSensorIntHumidity},
      $self->{t3hdSensorIntDewPoint}
  );
  # Int temp
  $label = lc $self->{t3hdSensorLabel}."_".$self->{t3hdSensorIntLabel}."_temp";
  $label =~ s/\s+/_/g;
  $self->set_thresholds(
      metric => $label,
      warning => 40,
      critical => 45,
  );
  my $intlevel_temp = $self->check_thresholds(
      metric => $label,
      value => $self->{t3hdSensorIntTemp},
  );
  $self->add_perfdata(
      label => $label,
      value => $self->{t3hdSensorIntTemp},
  );
  # Int hum
  $label = lc $self->{t3hdSensorLabel}."_".$self->{t3hdSensorIntLabel}."_hum";
  $label =~ s/\s+/_/g;
  $self->set_thresholds(
      metric => $label,
      warning => 70,
      critical => 80,
  );
  my $intlevel_hum = $self->check_thresholds(
      metric => $label,
      value => $self->{t3hdSensorIntHumidity},
  );
  $self->add_perfdata(
      label => $label,
      value => $self->{t3hdSensorIntHumidity},
      uom => "%",
  );
  # Int dew
  $label = lc $self->{t3hdSensorLabel}."_".$self->{t3hdSensorIntLabel}."_dewp";
  $label =~ s/\s+/_/g;
  $self->add_perfdata(
      label => $label,
      value => $self->{t3hdSensorIntDewPoint},
  );
  $self->add_message(($intlevel_temp == 2 || $intlevel_hum == 2) ? 2 : ($intlevel_temp == 1 || $intlevel_hum == 1) ? 1 : ($intlevel_temp == 3 || $intlevel_hum == 3) ? 3 : 0);

  # Ext temp a
  if ($self->{t3hdSensorExtAAvail}) {
    $self->add_info(sprintf "ext temperature %s is %.2f",
      $self->{t3hdSensorExtALabel},
      $self->{t3hdSensorExtATemp}
    );
    $label = lc $self->{t3hdSensorLabel}."_ext_".$self->{t3hdSensorExtALabel}."_temp";
    $label =~ s/\s+/_/g;
    $self->set_thresholds(
        metric => $label,
        warning => 40,
        critical => 45,
    );
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => $self->{t3hdSensorExtATemp},
    ));
    $self->add_perfdata(
        label => $label,
        value => $self->{t3hdSensorExtATemp},
    );
  }
  # Ext temp b
  if ($self->{t3hdSensorExtBAvail}) {
    $self->add_info(sprintf "ext temperature %s is %.2f",
      $self->{t3hdSensorExtBLabel},
      $self->{t3hdSensorExtBTemp}
    );
    $label = lc $self->{t3hdSensorLabel}."_ext_".$self->{t3hdSensorExtBLabel}."_temp";
    $label =~ s/\s+/_/g;
    $self->set_thresholds(
        metric => $label,
        warning => 40,
        critical => 45,
    );
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => $self->{t3hdSensorExtBTemp},
    ));
    $self->add_perfdata(
        label => $label,
        value => $self->{t3hdSensorExtBTemp},
    );
  }
}

__END__
VERTIV-V5-MIB::a2dSensorTable
VERTIV-V5-MIB::a2dSensorSerial.1 = 08151234
VERTIV-V5-MIB::a2dSensorLabel.1 = A2D_DC1_R5_FLOOD
VERTIV-V5-MIB::a2dSensorAvail.1 = 1
VERTIV-V5-MIB::a2dSensorValue.1 = 1
VERTIV-V5-MIB::a2dSensorDisplayValue.1 = Dry
VERTIV-V5-MIB::a2dSensorMode.1 = flood
VERTIV-V5-MIB::a2dSensorUnits.1 =
VERTIV-V5-MIB::a2dSensorMin.1 = 0
VERTIV-V5-MIB::a2dSensorMax.1 = 1
VERTIV-V5-MIB::a2dSensorLowLabel.1 = Wet
VERTIV-V5-MIB::a2dSensorHighLabel.1 = Dry
VERTIV-V5-MIB::a2dSensorAnalogLabel.1 = Flood

VERTIV-V5-MIB::a2dSensorTable
VERTIV-V5-MIB::a2dSensorSerial.1 = 4711123
VERTIV-V5-MIB::a2dSensorSerial.2 = ABC123
VERTIV-V5-MIB::a2dSensorLabel.1 = A2D
VERTIV-V5-MIB::a2dSensorLabel.2 = A2D
VERTIV-V5-MIB::a2dSensorAvail.1 = 1
VERTIV-V5-MIB::a2dSensorAvail.2 = 1
VERTIV-V5-MIB::a2dSensorValue.1 = 1
VERTIV-V5-MIB::a2dSensorValue.2 = 1
VERTIV-V5-MIB::a2dSensorDisplayValue.1 = Fault
VERTIV-V5-MIB::a2dSensorDisplayValue.2 = Wet
VERTIV-V5-MIB::a2dSensorMode.1 = wscFault
VERTIV-V5-MIB::a2dSensorMode.2 = wscLeak
VERTIV-V5-MIB::a2dSensorUnits.1 =
VERTIV-V5-MIB::a2dSensorUnits.2 =
VERTIV-V5-MIB::a2dSensorMin.1 = 0
VERTIV-V5-MIB::a2dSensorMin.2 = 0
VERTIV-V5-MIB::a2dSensorMax.1 = 1
VERTIV-V5-MIB::a2dSensorMax.2 = 1
VERTIV-V5-MIB::a2dSensorLowLabel.1 = OK
VERTIV-V5-MIB::a2dSensorLowLabel.2 = Dry
VERTIV-V5-MIB::a2dSensorHighLabel.1 = Fault
VERTIV-V5-MIB::a2dSensorHighLabel.2 = Wet
VERTIV-V5-MIB::a2dSensorAnalogLabel.1 = Leak Fault
VERTIV-V5-MIB::a2dSensorAnalogLabel.2 = Leak Sense

VERTIV-V5-MIB::a2dSensorTable
VERTIV-V5-MIB::a2dSensorSerial.1 = 83314A9FBA8744D2
VERTIV-V5-MIB::a2dSensorLabel.1 = A2D_DC1_R5_FLOOD
VERTIV-V5-MIB::a2dSensorAvail.1 = 1
VERTIV-V5-MIB::a2dSensorValue.1 = 1
VERTIV-V5-MIB::a2dSensorDisplayValue.1 = Open
VERTIV-V5-MIB::a2dSensorMode.1 = door
VERTIV-V5-MIB::a2dSensorUnits.1 = 
VERTIV-V5-MIB::a2dSensorMin.1 = 0
VERTIV-V5-MIB::a2dSensorMax.1 = 1
VERTIV-V5-MIB::a2dSensorLowLabel.1 = Closed
VERTIV-V5-MIB::a2dSensorHighLabel.1 = Open
VERTIV-V5-MIB::a2dSensorAnalogLabel.1 = Flood

Flood 0=Critical, 1=OK
Leak sense 0=OK, 1=Critical
Leak Fault 0=OK, 1=Critical
Door 0=OK, 1=Critical

Or are you asking about the critical message?

Perhaps this would be better: "CRITICAL - Sensor {SensorLabel} reports: {Low/HighLabel}"


VERTIV-V5-MIB::a2dSensorTable
VERTIV-V5-MIB::a2dSensorSerial.1 = 37DBC6571A1F6CD2
VERTIV-V5-MIB::a2dSensorSerial.2 = B5DB414DB96852D2
VERTIV-V5-MIB::a2dSensorLabel.1 = A2D
VERTIV-V5-MIB::a2dSensorLabel.2 = A2D
VERTIV-V5-MIB::a2dSensorAvail.1 = 1
VERTIV-V5-MIB::a2dSensorAvail.2 = 1
VERTIV-V5-MIB::a2dSensorValue.1 = 5
VERTIV-V5-MIB::a2dSensorValue.2 = 5
VERTIV-V5-MIB::a2dSensorDisplayValue.1 = 5.42
VERTIV-V5-MIB::a2dSensorDisplayValue.2 = 5.43
VERTIV-V5-MIB::a2dSensorMode.1 = customVoltage
VERTIV-V5-MIB::a2dSensorMode.2 = customVoltage
VERTIV-V5-MIB::a2dSensorUnits.1 = V
VERTIV-V5-MIB::a2dSensorUnits.2 = V
VERTIV-V5-MIB::a2dSensorMin.1 = 0
VERTIV-V5-MIB::a2dSensorMin.2 = 0
VERTIV-V5-MIB::a2dSensorMax.1 = 10
VERTIV-V5-MIB::a2dSensorMax.2 = 10
VERTIV-V5-MIB::a2dSensorLowLabel.1 =
VERTIV-V5-MIB::a2dSensorLowLabel.2 =
VERTIV-V5-MIB::a2dSensorHighLabel.1 =
VERTIV-V5-MIB::a2dSensorHighLabel.2 =
VERTIV-V5-MIB::a2dSensorAnalogLabel.1 = Custom (Voltage Mode)
VERTIV-V5-MIB::a2dSensorAnalogLabel.2 = Custom (Voltage Mode)

