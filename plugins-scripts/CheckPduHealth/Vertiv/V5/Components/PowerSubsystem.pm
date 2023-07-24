package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('VERTIV-V5-MIB', [

    ['totals', 'pduMainTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Totals'],
    ['phases', 'pduPhaseTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Phase'],
    ['breakers', 'pduBreakerTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Breaker'],
    ['outletswitches', 'pduOutletSwitchTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::OutletSwitch'],
    ['outletmeters', 'pduOutletMeterTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::OutletMeter'],
    ['transfers', 'pduTransferTable', 'CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Transfer'],
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{totals}}) {
    $_->check();
  }
  delete $self->{totals};
  $self->SUPER::check();
}



package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Totals;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{name} = ($self->{pduMainName} eq $self->{pduMainLabel}) ?
      $self->{pduMainName} :
      $self->{pduMainName}." (".$self->{pduMainLabel}.")";
}
sub check {
  my ($self) = @_;
  $self->add_info(sprintf("%s is %s, total power is %.2fW",
      $self->{name}, $self->{pduMainAvail},
      $self->{pduTotalRealPower},
  ));
  if ($self->{pduMainAvail} eq "Unavailable") {
    $self->add_critical();
  } elsif ($self->{pduMainAvail} eq "Partially Unavailable") {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
}


package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Phase;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{pduPhaseVoltage} /= 10;
  $self->{pduPhaseCurrent} /= 100;
  $self->{name} = ($self->{pduPhaseName} eq $self->{pduPhaseLabel}) ?
      $self->{pduPhaseName} :
      $self->{pduPhaseName}." (".$self->{pduPhaseLabel}.")";
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf("%s has %.2fV/%.2fA (%.2f%% balanced)",
      $self->{name},
      $self->{pduPhaseVoltage}, $self->{pduPhaseCurrent},
      $self->{pduPhaseBalance}
  ));
  $self->add_ok();
}


package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Breaker;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{name} = ($self->{pduBreakerName} eq $self->{pduBreakerLabel}) ?
      $self->{pduBreakerName} :
      $self->{pduBreakerName}." (".$self->{pduBreakerLabel}.")";
}

sub check {
  my ($self) = @_;
  if ($self->{pduBreakerLossOfLoadDetected} &&
      $self->{pduBreakerLossOfLoadDetected} ne "false") {
    # found, but maybe optional
    $self->add_warning(sprintf("loss of load detected for %s", $self->{name}));
  }
  if ($self->{pduBreakerResCurrentDetected} &&
      $self->{pduBreakerResCurrentDetected} ne "false") {
    # surely optional
    $self->add_warning(sprintf("residual current detected for %s", $self->{name}));
  }
}


package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::OutletSwitch;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{name} = ($self->{pduOutletSwitchName} eq $self->{pduOutletSwitchLabel}) ?
      $self->{pduOutletSwitchName} :
      $self->{pduOutletSwitchName}." (".$self->{pduOutletSwitchLabel}.")";
}

sub check {
  my ($self) = @_;
  if ($self->{pduOutletSwitchRelayFailure} ne "false" and
      $self->{pduOutletSwitchState} eq "on") {
    $self->add_critical(sprintf("%s has a relay failure", $self->{name}));
  } elsif ($self->{pduOutletSwitchRelayFailure} ne "false") {
    $self->add_warning(sprintf("%s has a relay failure", $self->{name}));
  }
}


package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::OutletMeter;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{name} = ($self->{pduOutletMeterName} eq $self->{pduOutletMeterLabel}) ?
      $self->{pduOutletMeterName} :
      $self->{pduOutletMeterName}." (".$self->{pduOutletMeterLabel}.")";
  $self->{pduOutletMeterVoltage} /= 10;
  $self->{pduOutletMeterCurrent} /= 100;
}

sub check {
  my ($self) = @_;
  $self->add_perfdata(label => $self->{name}."_V",
      value => $self->{pduOutletMeterVoltage});
  $self->add_perfdata(label => $self->{name}."_A",
      value => $self->{pduOutletMeterCurrent});
}


package CheckPduHealth::Vertiv::V5::Components::PowerSubsystem::Transfer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
# pduTransferHardwareFault != false

