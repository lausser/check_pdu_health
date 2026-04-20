package CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Enum severity mappings (SNMP enum values are pre-converted to strings by GLPlugin)
# Severity levels: 0=OK, 1=WARNING, 2=CRITICAL
my %LoadStateSeverity = (
  'normal' => 0,
  'overLoaded' => 2,
  'nearOverLoaded' => 1,
  'lowLoad' => 0,
  'noLoadNormal' => 0,
);

sub init {
  my $self = shift;

  # Fetch device identity
  $self->get_snmp_objects('PowerNet-MIB', qw(
    rPDU2IdentModelNumber rPDU2IdentSerialNumber rPDU2IdentFirmwareVersion
  ));

  # Default values (will be counted when we fetch tables)
  $self->{rPDU2DevicePropertiesNumMeteredBanks} = 0;
  $self->{rPDU2DevicePropertiesNumPhases} = 0;

  # Fetch device status & config
  $self->get_snmp_tables('PowerNet-MIB', [
    ['device_status', 'rPDU2DeviceStatusTable', 'CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::DeviceStatus'],
    ['device_config', 'rPDU2DeviceConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phase_status', 'rPDU2PhaseStatusTable', 'CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::PhaseStatus'],
    ['phase_config', 'rPDU2PhaseConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);

  # Always try to fetch bank tables (empty if NumMeteredBanks = 0)
  $self->get_snmp_tables('PowerNet-MIB', [
    ['bank_status', 'rPDU2BankStatusTable', 'CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::BankStatus'],
    ['bank_config', 'rPDU2BankConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);

  # Merge config tables into status tables using module+number as join key
  $self->merge_tables_with_code("device_status", "device_config", sub {
    my($sta, $cfg) = @_;
    return ($sta->{rPDU2DeviceStatusModule} == $cfg->{rPDU2DeviceConfigModule}) ? 1 : 0;
  });

  $self->merge_tables_with_code("phase_status", "phase_config", sub {
    my($sta, $cfg) = @_;
    return (
      $sta->{rPDU2PhaseStatusModule} == $cfg->{rPDU2PhaseConfigModule} &&
      $sta->{rPDU2PhaseStatusNumber} == $cfg->{rPDU2PhaseConfigNumber}
    ) ? 1 : 0;
  });

  $self->merge_tables_with_code("bank_status", "bank_config", sub {
    my($sta, $cfg) = @_;
    return (
      $sta->{rPDU2BankStatusModule} == $cfg->{rPDU2BankConfigModule} &&
      $sta->{rPDU2BankStatusNumber} == $cfg->{rPDU2BankConfigNumber}
    ) ? 1 : 0;
  });

  # Count actual fetched rows for debug output
  my $device_status_count = $self->{device_status} ? scalar(@{$self->{device_status}}) : 0;
  my $phase_status_count = $self->{phase_status} ? scalar(@{$self->{phase_status}}) : 0;
  my $bank_status_count = $self->{bank_status} ? scalar(@{$self->{bank_status}}) : 0;

  # Update the cached NumPhases and NumMeteredBanks based on actual rows fetched
  $self->{rPDU2DevicePropertiesNumPhases} = $phase_status_count if $phase_status_count > 0;
  $self->{rPDU2DevicePropertiesNumMeteredBanks} = $bank_status_count if $bank_status_count > 0;

  # Store subtree info for verbose output
  $self->{_subtree_used} = 'rPDU2';
  $self->{_device_count} = $device_status_count;
  $self->{_phase_count} = $phase_status_count;
  $self->{_bank_count} = $bank_status_count;
}

sub check {
  my $self = shift;

  # Log diagnostic info about which subtree and data were found (internal only)
  if (defined $self->{_subtree_used}) {
    $self->debug(sprintf("OID subtree: %s (%d device, %d phase, %d bank)",
      $self->{_subtree_used},
      $self->{_device_count} // 0,
      $self->{_phase_count} // 0,
      $self->{_bank_count} // 0
    ));
  }

  $self->SUPER::check();

  # If no specific messages were generated (empty tables), add informative summary
  if (!$self->check_messages()) {
    if ($self->{rPDU2DevicePropertiesNumPhases} == 0 &&
        $self->{rPDU2DevicePropertiesNumMeteredBanks} == 0) {
      $self->add_ok('device identified but no power data available (no phases, no banks)');
    } else {
      $self->add_ok('power metrics within limits');
    }
  }

  $self->reduce_messages_short();
}


package CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::DeviceStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  # Scale device status values
  $self->{rPDU2DeviceStatusPower} = $self->{rPDU2DeviceStatusPower} / 100 if defined $self->{rPDU2DeviceStatusPower} && $self->{rPDU2DeviceStatusPower} >= 0;
  $self->{rPDU2DeviceStatusApparentPower} = $self->{rPDU2DeviceStatusApparentPower} / 100 if defined $self->{rPDU2DeviceStatusApparentPower} && $self->{rPDU2DeviceStatusApparentPower} >= 0;
  $self->{rPDU2DeviceStatusPowerFactor} = $self->{rPDU2DeviceStatusPowerFactor} / 100 if defined $self->{rPDU2DeviceStatusPowerFactor} && $self->{rPDU2DeviceStatusPowerFactor} >= 0;
  $self->{rPDU2DeviceStatusEnergy} = $self->{rPDU2DeviceStatusEnergy} / 10 if defined $self->{rPDU2DeviceStatusEnergy} && $self->{rPDU2DeviceStatusEnergy} >= 0;
  $self->{rPDU2DeviceStatusPeakPower} = $self->{rPDU2DeviceStatusPeakPower} / 100 if defined $self->{rPDU2DeviceStatusPeakPower} && $self->{rPDU2DeviceStatusPeakPower} >= 0;
}

sub check {
  my $self = shift;

  # Device load state (enum values are strings)
  my $load_state = $self->{rPDU2DeviceStatusLoadState} // '';
  $self->add_info(sprintf("device load state: %s", $load_state // 'unknown'));
  my $load_severity = $LoadStateSeverity{$load_state} // 0;
  $self->add_message($load_severity, "");

  # Power threshold checking
  if (defined $self->{rPDU2DeviceStatusPower} && defined $self->{rPDU2DeviceConfigNearOverloadPowerThreshold}) {
    $self->set_thresholds(
      metric => 'power',
      warning => $self->{rPDU2DeviceConfigNearOverloadPowerThreshold} / 10,
      critical => $self->{rPDU2DeviceConfigOverloadPowerThreshold} / 10
    );
    $self->add_message(
      $self->check_thresholds(
        metric => 'power',
        value => $self->{rPDU2DeviceStatusPower}
      ),
      sprintf("device power %.2f kW", $self->{rPDU2DeviceStatusPower})
    );
  }

  # Emit perfdata for power metrics (thresholds set via set_thresholds above)
  $self->add_perfdata(
    label => 'power',
    value => $self->{rPDU2DeviceStatusPower},
    thresholds => 1
  ) if defined $self->{rPDU2DeviceStatusPower};

  $self->add_perfdata(
    label => 'apparent_power',
    value => $self->{rPDU2DeviceStatusApparentPower}
  ) if defined $self->{rPDU2DeviceStatusApparentPower};

  $self->add_perfdata(
    label => 'power_factor',
    value => $self->{rPDU2DeviceStatusPowerFactor}
  ) if defined $self->{rPDU2DeviceStatusPowerFactor};

  # Energy: monotonic counter, use 'c' UOM
  $self->add_perfdata(
    label => 'energy',
    value => $self->{rPDU2DeviceStatusEnergy},
    uom => 'c'
  ) if defined $self->{rPDU2DeviceStatusEnergy};

  $self->add_perfdata(
    label => 'power_peak',
    value => $self->{rPDU2DeviceStatusPeakPower}
  ) if defined $self->{rPDU2DeviceStatusPeakPower};
}


package CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::PhaseStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  # Scale phase status values
  $self->{rPDU2PhaseStatusCurrent} = $self->{rPDU2PhaseStatusCurrent} / 10 if defined $self->{rPDU2PhaseStatusCurrent} && $self->{rPDU2PhaseStatusCurrent} >= 0;
  $self->{rPDU2PhaseStatusPower} = $self->{rPDU2PhaseStatusPower} / 100 if defined $self->{rPDU2PhaseStatusPower} && $self->{rPDU2PhaseStatusPower} >= 0;
  $self->{rPDU2PhaseStatusApparentPower} = $self->{rPDU2PhaseStatusApparentPower} / 100 if defined $self->{rPDU2PhaseStatusApparentPower} && $self->{rPDU2PhaseStatusApparentPower} >= 0;
  $self->{rPDU2PhaseStatusPowerFactor} = $self->{rPDU2PhaseStatusPowerFactor} / 100 if defined $self->{rPDU2PhaseStatusPowerFactor} && $self->{rPDU2PhaseStatusPowerFactor} >= 0;
  $self->{rPDU2PhaseStatusPeakCurrent} = $self->{rPDU2PhaseStatusPeakCurrent} / 10 if defined $self->{rPDU2PhaseStatusPeakCurrent} && $self->{rPDU2PhaseStatusPeakCurrent} >= 0;
  $self->{phase_index} = $self->{flat_indices};
  $self->{phase_index} =~ s/\..*$//;
}

sub check {
  my $self = shift;
  my $phase_idx = $self->{phase_index};

  # Always emit phase status info
  $self->add_info(sprintf("phase %d: %s (%.2f A, %.2f kW, %d V)",
    $phase_idx, $self->{rPDU2PhaseStatusLoadState} // 'unknown',
    $self->{rPDU2PhaseStatusCurrent} // 0,
    $self->{rPDU2PhaseStatusPower} // 0,
    $self->{rPDU2PhaseStatusVoltage} // 0));

  # Map load state to severity (enum values are strings after SNMP translation)
  if ($self->{rPDU2PhaseStatusLoadState} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{rPDU2PhaseStatusLoadState} eq 'overLoaded') {
    $self->add_critical();
  } elsif ($self->{rPDU2PhaseStatusLoadState} eq 'nearOverLoaded') {
    $self->add_warning();
  } elsif ($self->{rPDU2PhaseStatusLoadState} eq 'lowLoad') {
    $self->add_ok();
  } elsif ($self->{rPDU2PhaseStatusLoadState} eq 'noLoadNormal') {
    $self->add_ok();
  } else {
    $self->add_ok();  # unknown state defaults to OK
  }

  # Current threshold checking
  if (defined $self->{rPDU2PhaseStatusCurrent} && defined $self->{rPDU2PhaseConfigNearOverloadCurrentThreshold}) {
    $self->set_thresholds(
      metric => "phase${phase_idx}_current",
      warning => $self->{rPDU2PhaseConfigNearOverloadCurrentThreshold},
      critical => $self->{rPDU2PhaseConfigOverloadCurrentThreshold}
    );
    $self->add_message(
      $self->check_thresholds(
        metric => "phase${phase_idx}_current",
        value => $self->{rPDU2PhaseStatusCurrent}
      ),
      sprintf("phase %d current %.2f A", $phase_idx, $self->{rPDU2PhaseStatusCurrent})
    );
  }

  # Emit perfdata with thresholds (set via set_thresholds above)
  my $label_prefix = "phase${phase_idx}";

  $self->add_perfdata(
    label => "${label_prefix}_current",
    value => $self->{rPDU2PhaseStatusCurrent},
    thresholds => 1
  ) if defined $self->{rPDU2PhaseStatusCurrent};

  $self->add_perfdata(
    label => "${label_prefix}_voltage",
    value => $self->{rPDU2PhaseStatusVoltage}
  ) if defined $self->{rPDU2PhaseStatusVoltage};

  $self->add_perfdata(
    label => "${label_prefix}_power",
    value => $self->{rPDU2PhaseStatusPower}
  ) if defined $self->{rPDU2PhaseStatusPower};

  $self->add_perfdata(
    label => "${label_prefix}_apparent_power",
    value => $self->{rPDU2PhaseStatusApparentPower}
  ) if defined $self->{rPDU2PhaseStatusApparentPower};

  $self->add_perfdata(
    label => "${label_prefix}_power_factor",
    value => $self->{rPDU2PhaseStatusPowerFactor}
  ) if defined $self->{rPDU2PhaseStatusPowerFactor};

  $self->add_perfdata(
    label => "${label_prefix}_peak_current",
    value => $self->{rPDU2PhaseStatusPeakCurrent}
  ) if defined $self->{rPDU2PhaseStatusPeakCurrent};
}


package CheckPduHealth::APC::Powermib::PDU::Components::PowerSubsystem::BankStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  # Scale bank status values (same as phase)
  $self->{rPDU2BankStatusCurrent} = $self->{rPDU2BankStatusCurrent} / 10 if defined $self->{rPDU2BankStatusCurrent} && $self->{rPDU2BankStatusCurrent} >= 0;
  $self->{rPDU2BankStatusPower} = $self->{rPDU2BankStatusPower} / 100 if defined $self->{rPDU2BankStatusPower} && $self->{rPDU2BankStatusPower} >= 0;
  $self->{rPDU2BankStatusApparentPower} = $self->{rPDU2BankStatusApparentPower} / 100 if defined $self->{rPDU2BankStatusApparentPower} && $self->{rPDU2BankStatusApparentPower} >= 0;
  $self->{rPDU2BankStatusPowerFactor} = $self->{rPDU2BankStatusPowerFactor} / 100 if defined $self->{rPDU2BankStatusPowerFactor} && $self->{rPDU2BankStatusPowerFactor} >= 0;
  $self->{rPDU2BankStatusPeakCurrent} = $self->{rPDU2BankStatusPeakCurrent} / 10 if defined $self->{rPDU2BankStatusPeakCurrent} && $self->{rPDU2BankStatusPeakCurrent} >= 0;
  $self->{bank_index} = $self->{flat_indices};
  $self->{bank_index} =~ s/\..*$//;
}

sub check {
  my $self = shift;
  my $bank_idx = $self->{bank_index};

  # Always emit bank status info
  $self->add_info(sprintf("bank %d: %s (%.2f A, %.2f kW, %d V)",
    $bank_idx, $self->{rPDU2BankStatusLoadState} // 'unknown',
    $self->{rPDU2BankStatusCurrent} // 0,
    $self->{rPDU2BankStatusPower} // 0,
    $self->{rPDU2BankStatusVoltage} // 0));

  # Map load state to severity (enum values are strings)
  if ($self->{rPDU2BankStatusLoadState} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{rPDU2BankStatusLoadState} eq 'overLoaded') {
    $self->add_critical();
  } elsif ($self->{rPDU2BankStatusLoadState} eq 'nearOverLoaded') {
    $self->add_warning();
  } elsif ($self->{rPDU2BankStatusLoadState} eq 'lowLoad') {
    $self->add_ok();
  } elsif ($self->{rPDU2BankStatusLoadState} eq 'noLoadNormal') {
    $self->add_ok();
  } else {
    $self->add_ok();  # unknown state defaults to OK
  }

  # Current threshold checking
  if (defined $self->{rPDU2BankStatusCurrent} && defined $self->{rPDU2BankConfigNearOverloadCurrentThreshold}) {
    $self->set_thresholds(
      metric => "bank${bank_idx}_current",
      warning => $self->{rPDU2BankConfigNearOverloadCurrentThreshold},
      critical => $self->{rPDU2BankConfigOverloadCurrentThreshold}
    );
    $self->add_message(
      $self->check_thresholds(
        metric => "bank${bank_idx}_current",
        value => $self->{rPDU2BankStatusCurrent}
      ),
      sprintf("bank %d current %.2f A", $bank_idx, $self->{rPDU2BankStatusCurrent})
    );
  }

  # Emit perfdata with thresholds (set via set_thresholds above)
  my $label_prefix = "bank${bank_idx}";

  $self->add_perfdata(
    label => "${label_prefix}_current",
    value => $self->{rPDU2BankStatusCurrent},
    thresholds => 1
  ) if defined $self->{rPDU2BankStatusCurrent};

  $self->add_perfdata(
    label => "${label_prefix}_voltage",
    value => $self->{rPDU2BankStatusVoltage}
  ) if defined $self->{rPDU2BankStatusVoltage};

  $self->add_perfdata(
    label => "${label_prefix}_power",
    value => $self->{rPDU2BankStatusPower}
  ) if defined $self->{rPDU2BankStatusPower};

  $self->add_perfdata(
    label => "${label_prefix}_apparent_power",
    value => $self->{rPDU2BankStatusApparentPower}
  ) if defined $self->{rPDU2BankStatusApparentPower};

  $self->add_perfdata(
    label => "${label_prefix}_power_factor",
    value => $self->{rPDU2BankStatusPowerFactor}
  ) if defined $self->{rPDU2BankStatusPowerFactor};

  $self->add_perfdata(
    label => "${label_prefix}_peak_current",
    value => $self->{rPDU2BankStatusPeakCurrent}
  ) if defined $self->{rPDU2BankStatusPeakCurrent};
}


1;
