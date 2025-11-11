package CheckPduHealth::AvocentPM::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AVOCENT-PM-MIB', [

    ['pmPowerMgmtPDU', 'pmPowerMgmtPDUTable', 'CheckPduHealth::AvocentPM::Components::PowerSubsystem::pmPowerMgmtPDUTable'],
    ['pmPowerMgmtOutlets', 'pmPowerMgmtOutletsTable', 'CheckPduHealth::AvocentPM::Components::PowerSubsystem::pmPowerMgmtOutletsTable'],
  ]);
}


package CheckPduHealth::AvocentPM::Components::PowerSubsystem::pmPowerMgmtPDUTable;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;

  my $label = sprintf 'PDU_%s_%s_%s', $self->{pmPowerMgmtPDUTableVendor},
      $self->{pmPowerMgmtPDUTableModel}, $self->{pmPowerMgmtPDUTablePduId};

  $self->add_info(sprintf '%s is %s', $label, $self->{pmPowerMgmtPDUTableAlarm});

  if ($self->{pmPowerMgmtPDUTableAlarm} eq "normal") {
    $self->add_ok();
  } elsif ($self->{pmPowerMgmtPDUTableAlarm} =~ /high-warning|low-warning/) {
    $self->add_warning();
  } elsif ($self->{pmPowerMgmtPDUTableAlarm} =~ /blow-fuse|hw-ocp|high-critical|low-critical/) {
    $self->add_critical();
  }

  $self->set_thresholds(
      metric => "current",
      warning => $self->{pmPowerMgmtPDUTableCurrentLowWarning} / 10 .":".
          $self->{pmPowerMgmtPDUTableCurrentHighWarning} / 10,
      critical => $self->{pmPowerMgmtPDUTableCurrentLowCritical} / 10 .":".
          $self->{pmPowerMgmtPDUTableCurrentHighCritical} / 10,
  );
  $self->add_perfdata(
      label => $label . "_current",
      value => $self->{pmPowerMgmtPDUTableCurrentValue} / 10,
  );
  $self->add_perfdata(
      label => $label . "_voltage",
      value => $self->{pmPowerMgmtPDUTableVoltageValue},
  );
  $self->add_perfdata(
      label => $label . "_power",
      value => $self->{pmPowerMgmtPDUTablePowerValue} / 10,
  );
  $self->add_perfdata(
      label => $label . "_power-factor",
      value => $self->{pmPowerMgmtPDUTablePowerFactorValue} / 100,
  );
  $self->add_perfdata(
      label => $label . "_energy",
      value => $self->{pmPowerMgmtPDUTableEnergyValue} / 1000,
  );

}


package CheckPduHealth::AvocentPM::Components::PowerSubsystem::pmPowerMgmtOutletsTable;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;

  my $label = sprintf 'Outlet_%i_%i_%s', $self->{pmPowerMgmtOutletsTablePduNumber},
      $self->{pmPowerMgmtOutletsTableNumber}, $self->{pmPowerMgmtOutletsTableName};

  $self->add_info(sprintf '%s is %s', $label, $self->{pmPowerMgmtOutletsTableAlarm});

  if ($self->{pmPowerMgmtOutletsTableAlarm} eq "normal") {
    $self->add_ok();
  } elsif ($self->{pmPowerMgmtOutletsTableAlarm} =~ /high-warning|low-warning/) {
    $self->add_warning();
  } elsif ($self->{pmPowerMgmtOutletsTableAlarm} =~ /blow-fuse|hw-ocp|high-critical|low-critical/) {
    $self->add_critical();
  }

  $self->set_thresholds(
      metric => "current",
      warning => $self->{pmPowerMgmtOutletsTableCurrentLowWarning} / 10 .":".
          $self->{pmPowerMgmtOutletsTableCurrentHighWarning} / 10,
      critical => $self->{pmPowerMgmtOutletsTableCurrentLowCritical} / 10 .":".
          $self->{pmPowerMgmtOutletsTableCurrentHighCritical} / 10,
  );
  $self->add_perfdata(
      label => $label . "_current",
      value => $self->{pmPowerMgmtOutletsTableCurrentValue} / 10,
  );
  $self->add_perfdata(
      label => $label . "_voltage",
      value => $self->{pmPowerMgmtOutletsTableVoltageValue},
  );
  $self->add_perfdata(
      label => $label . "_power",
      value => $self->{pmPowerMgmtOutletsTablePowerValue} / 10,
  );
  $self->add_perfdata(
      label => $label . "_power-factor",
      value => $self->{pmPowerMgmtOutletsTablePowerFactorValue} / 100,
  );
  $self->add_perfdata(
      label => $label . "_energy",
      value => $self->{pmPowerMgmtOutletsTableEnergyValue} / 1000,
  );
}
__END__
