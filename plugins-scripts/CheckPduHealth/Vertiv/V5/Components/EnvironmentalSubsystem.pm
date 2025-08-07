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
      critical => 50,
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{t3hdSensorIntTemp},
  ));
  $self->add_perfdata(
      label => $label,
      value => $self->{t3hdSensorIntTemp},
  );
  # Int hum
  $label = lc $self->{t3hdSensorLabel}."_".$self->{t3hdSensorIntLabel}."_hum";
  $label =~ s/\s+/_/g;
  $self->set_thresholds(
      metric => $label,
      warning => 50,
      critical => 70,
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{t3hdSensorIntHumidity},
  ));
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
        critical => 50,
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
        critical => 50,
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
