package CheckPduHealth::AvocentPM::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('AVOCENT-PM-MIB', qw(
      pmFirmwareVersion pmBootcodeVersion pmProductModel
      pmSerialNumber));
  $self->get_snmp_tables('AVOCENT-PM-MIB', [
      ['pmPowerMgmtSensors', 'pmPowerMgmtSensorsTable', 'CheckPduHealth::AvocentPM::Components::EnvironmentalSubsystem::pmPowerMgmtSensor'],
  ]);
}

sub check {
  my $self = shift;
  $self->SUPER::check();
  $self->add_info(sprintf '%s (Sn: %s) running %s found',
      $self->{pmProductModel}, $self->{pmSerialNumber},
      $self->{pmFirmwareVersion});
}


package CheckPduHealth::AvocentPM::Components::EnvironmentalSubsystem::pmPowerMgmtSensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;

  if ($self->{pmPowerMgmtSensorsTableType} =~ /temp-internal|temperature|humidity/) {
    my $unit = "";
    if ($self->{pmPowerMgmtSensorsTableUnit} eq "celsius") {
      $unit = "°C";
    } elsif ($self->{pmPowerMgmtSensorsTableUnit} eq "fahrenheit") {
      $unit = "°F";
    } elsif ($self->{pmPowerMgmtSensorsTableUnit} eq "percent") {
      $unit = "%";
    }

    my $label = sprintf '%i_%s', $self->{pmPowerMgmtSensorsTableNumber}, $self->{pmPowerMgmtSensorsTableName};

    $self->add_info(sprintf '%s (%s) is %s%s',
        $label, $self->{pmPowerMgmtSensorsTableType},
        ($self->{pmPowerMgmtSensorsTableValueInt} + 1) / 10, $unit);
    $self->set_thresholds(
        metric => $label,
        warning => ($self->{pmPowerMgmtSensorsTableLowWarning} + 1) / 10 .":".
            ($self->{pmPowerMgmtSensorsTableHighWarning} + 1) / 10,
        critical => ($self->{pmPowerMgmtSensorsTableLowCritical} + 1) / 10 .":".
            ($self->{pmPowerMgmtSensorsTableHighCritical} + 1) / 10,
    );
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => ($self->{pmPowerMgmtSensorsTableValueInt} + 1) / 10
    ));
    $self->add_perfdata(
        label => $label,
        value => ($self->{pmPowerMgmtSensorsTableValueInt} + 1)/ 10,
    );

  } elsif ($self->{pmPowerMgmtSensorsTableType} =~ /smoke|dry-concact|water-level|motion/) { # yes, the typo for dry-contact is in the MIB
    my $label = sprintf '%i_%s', $self->{pmPowerMgmtSensorsTableNumber}, $self->{pmPowerMgmtSensorsTableName};

    $self->add_info(sprintf '%s (%s) is %s%s',
        $label, $self->{pmPowerMgmtSensorsTableType},
        $self->{pmPowerMgmtSensorsTableStatus});

    if ($self->{pmPowerMgmtSensorsTableStatus} eq "normal") {
      $self->add_ok();
    } elsif ($self->{pmPowerMgmtSensorsTableStatus} eq "triggered") {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }

  } else {
    $self->annotate_info("UNSUPPORTED SENSOR TYPE!!");
    $self->add_ok();
  }
}

__END__
