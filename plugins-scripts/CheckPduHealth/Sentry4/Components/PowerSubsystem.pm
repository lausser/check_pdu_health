package CheckPduHealth::Sentry4::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('Sentry4-MIB', [
    ['unitconfigs', 'st4UnitConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['unitmonitors', 'st4UnitMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::Unit'],
    ['uniteventconfigs', 'st4UnitEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['cordconfigs', 'st4InputCordConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['cordmonitors', 'st4InputCordMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::InputCord'],
    ['cordeventconfigs', 'st4InputCordEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['lineconfigs', 'st4LineConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['linemonitors', 'st4LineMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::Line'],
    ['lineeventconfigs', 'st4LineEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phaseconfigs', 'st4PhaseConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['phasemonitors', 'st4PhaseMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::Phase'],
    ['phaseeventconfigs', 'st4PhaseEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['ocpconfigs', 'st4OcpConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['ocpmonitors', 'st4OcpMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::OCP'],
    ['ocpeventmon', 'st4OcpEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['branchconfigs', 'st4BranchConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['branchmonitors', 'st4BranchMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::Branch'],
    ['brancheventconfigs', 'st4BranchEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['outletconfigs', 'st4OutletConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['outletmonitors', 'st4OutletMonitorTable', 'CheckPduHealth::Sentry4::Components::PowerSubsystem::Outlet'],
    ['outleteventconfigs', 'st4OutletEventConfigTable', 'Monitoring::GLPlugin::SNMP::TableItem'],

    ['outletcontrols', 'st4OutletControlTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  foreach (qw(unit cord line phase ocp branch)) {
    $self->merge($_.'monitors', $_.'configs', $_.'eventconfigs');
  }
  $self->merge(qw(outletmonitors outletconfigs outleteventconfigs outletcontrols));

  foreach my $unit (@{$self->{unitmonitors}}) {
    foreach my $cord (@{$self->{cordmonitors}}) {
      push(@{$unit->{cords}}, $cord) if $cord->{indices}->[0] == $unit->{indices}->[0];
    }
  }
  foreach my $cord (@{$self->{cordmonitors}}) {
    foreach my $itemname (qw(line phase ocp branch outlet)) {
      foreach my $item (@{$self->{$itemname.'monitors'}}) {
        push(@{$cord->{$itemname.'s'}}, $item) if $item->{indices}->[0] == $cord->{indices}->[0] && $item->{indices}->[1] == $cord->{indices}->[1];
      }
    }
  }
}

sub merge {
  my $self = shift;
  my($monitors, $configs, $eventconfigs, $controls) = @_;
  foreach my $sm (@{$self->{$monitors}}) {
    foreach my $sc (grep { $sm->{flat_indices} eq $_->{flat_indices} } @{$self->{$configs}}) {
      map { $sm->{$_} = $sc->{$_} } keys %{$sc};
    }
    foreach my $sec (grep { $sm->{flat_indices} eq $_->{flat_indices} } @{$self->{$eventconfigs}}) {
      map { $sm->{$_} = $sec->{$_} } keys %{$sec};
    }
    next if ! $controls;
    foreach my $con (grep { $sm->{flat_indices} eq $_->{flat_indices} } @{$self->{$controls}}) {
      map { $sm->{$_} = $con->{$_} } keys %{$con};
    }
  }
  delete $self->{$configs};
  delete $self->{$eventconfigs};
  delete $self->{$controls} if $controls;
}

sub check {
  my $self = shift;
  $self->add_info('check units');
  foreach my $unit (@{$self->{unitmonitors}}) {
    $unit->check();
  }
}


package CheckPduHealth::Sentry4::Components::PowerSubsystem::Unit;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{cords} = [];
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'unit %s status is %s',
      $self->{st4UnitName}, $self->{st4UnitStatus});
  if ($self->{st4UnitStatus} ne 'normal') {
    $self->add_warning();
  } else {
    $self->add_ok(sprintf 'unit %s with %d input cords',
        $self->{st4UnitName}, scalar(@{$self->{cords}}));
  }
  foreach my $cord (@{$self->{cords}}) {
    $cord->check();
  }
}


package CheckPduHealth::Sentry4::Components::PowerSubsystem::InputCord;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{lines} = [];
  $self->{phases} = [];
  $self->{ocps} = [];
  $self->{branches} = [];
  $self->{outlets} = [];
}

sub check {
  my $self = shift;
  $self->{st4InputCordNominalVoltage} /= 10;
  $self->{st4InputCordOutOfBalance} /= 10;
  $self->{st4InputCordPowerFactor} /= 100;
  $self->{st4InputCordPowerFactorLowAlarm} /= 100;
  $self->{st4InputCordPowerFactorLowWarning} /= 100;
  $self->add_info(sprintf '%s cord %s status is %s',
      $self->{st4InputCordInletType}, $self->{st4InputCordName},
      $self->{st4InputCordStatus});
  if ($self->{st4InputCordStatus} ne 'normal') {
    $self->add_warning();
  } else {
    $self->add_ok(sprintf 'cord %s with %d lines and %d outlets',
        $self->{st4InputCordName},
        scalar(@{$self->{lines}}), scalar(@{$self->{outlets}}));
  }
  $self->add_info(sprintf '%s active power status is %s',
      $self->{st4InputCordName}, $self->{st4InputCordActivePowerStatus});
  if ($self->{st4InputCordActivePowerStatus} ne 'normal' && $self->{st4InputCordStatus} ne 'normal') {
    $self->add_warning();
  }
  $self->add_info(sprintf '%s apparent power status is %s',
      $self->{st4InputCordName}, $self->{st4InputCordApparentPowerStatus});
  if ($self->{st4InputCordApparentPowerStatus} ne 'normal' && $self->{st4InputCordStatus} ne 'normal') {
    $self->add_warning();
  }
  $self->add_info(sprintf '%s out of balance status is %s',
      $self->{st4InputCordName}, $self->{st4InputCordOutOfBalanceStatus});
  if ($self->{st4InputCordOutOfBalanceStatus} ne 'normal' && $self->{st4InputCordStatus} ne 'normal') {
    $self->add_warning();
  }
  $self->add_info(sprintf '%s power factor status is %s',
      $self->{st4InputCordName}, $self->{st4InputCordPowerFactorStatus});
  if ($self->{st4InputCordPowerFactorStatus} ne 'normal' && $self->{st4InputCordStatus} ne 'normal') {
    $self->add_warning();
  }
  $self->add_perfdata(
      label => $self->{st4InputCordName}.'_active_VA',
      value => $self->{st4InputCordActivePower},
      warning => $self->{st4InputCordActivePowerLowWarning}.':'.$self->{st4InputCordActivePowerHighWarning},
      critical => $self->{st4InputCordActivePowerLowAlarm}.':'.$self->{st4InputCordActivePowerHighAlarm},
      max => $self->{st4InputCordPowerCapacity},
  );
  $self->add_perfdata(
      label => $self->{st4InputCordName}.'_apparent_VA',
      value => $self->{st4InputCordApparentPower},
      warning => $self->{st4InputCordApparentPowerLowWarning}.':'.$self->{st4InputCordApparentPowerHighWarning},
      critical => $self->{st4InputCordApparentPowerLowAlarm}.':'.$self->{st4InputCordApparentPowerHighAlarm},
      max => $self->{st4InputCordPowerCapacity},
  );
  $self->add_perfdata(
      label => $self->{st4InputCordName}.'_VA_utilized',
      value => $self->{st4InputCordPowerUtilized},
      uom => '%',
  );
  $self->add_perfdata(
      label => $self->{st4InputCordName}.'_out_of_balance',
      value => $self->{st4InputCordOutOfBalance},
      warning => $self->{st4InputCordOutOfBalanceHighWarning},
      critical => $self->{st4InputCordOutOfBalanceHighAlarm},
  );
  $self->add_perfdata(
      label => $self->{st4InputCordName}.'_power_factor',
      value => $self->{st4InputCordPowerFactor},
      warning => $self->{st4InputCordPowerFactorLowWarning}.':',
      critical => $self->{st4InputCordPowerFactorLowAlarm}.':',
  );
  foreach my $line (@{$self->{lines}}) {
    $line->check();
  }
  foreach my $phase (@{$self->{phases}}) {
    $phase->check();
  }
  foreach my $ocp (@{$self->{ocps}}) {
    $ocp->check();
  }
  foreach my $branch (@{$self->{branches}}) {
    $branch->check();
  }
  foreach my $outlet (@{$self->{outlets}}) {
    $outlet->check();
  }
}


package CheckPduHealth::Sentry4::Components::PowerSubsystem::Line;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->{st4LineCurrentUtilized} /= 10;
  $self->{st4LineCurrent} /= 100;
  $self->{st4LineCurrentHighAlarm} /= 10;
  $self->{st4LineCurrentHighWarning} /= 10;
  $self->{st4LineCurrentLowAlarm} /= 10;
  $self->{st4LineCurrentLowWarning} /= 10;
  $self->add_info(sprintf 'line %s status is %s state is %s',
      $self->{st4LineID}, $self->{st4LineStatus}, $self->{st4LineState});
  if ($self->{st4LineState} eq 'on') {
    if ($self->{st4LineStatus} =~ /normal|disabled|purged|reading|settle/) {
      $self->add_ok();
    } elsif ($self->{st4LineStatus} =~ /lowWarning|highWarning/) {
      $self->add_warning();
    } elsif ($self->{st4LineStatus} =~ /readError|pwrError|breakerTripped|fuseBlown|lowAlarm|highAlarm|alarm|underLimit|overLimit|nvmFail|profileError|conflict/) {
      $self->add_critical();
    } elsif ($self->{st4LineStatus} =~ /notFound|lost|noComm|/) {
      $self->add_unknown();
    }
  }
  $self->add_perfdata(
      label => 'line_'.$self->{st4LineID}.'_usage',
      value => $self->{st4LineCurrentUtilized},
      uom => '%',
  );
  $self->add_perfdata(
      label => 'line_'.$self->{st4LineID}.'_amps',
      value => $self->{st4LineCurrent},
      warning => $self->{st4LineCurrentLowWarning}.':'.$self->{st4LineCurrentHighWarning},
      critical => $self->{st4LineCurrentLowAlarm}.':'.$self->{st4LineCurrentHighAlarm},
      max => $self->{st4LineCurrentCapacity},
  );
}

package CheckPduHealth::Sentry4::Components::PowerSubsystem::Phase;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);


package CheckPduHealth::Sentry4::Components::PowerSubsystem::OCP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'ocp %s status is %s',
      $self->{st4OcpLabel}, $self->{st4OcpStatus});
  if ($self->{st4OcpStatus} ne 'normal') {
    $self->add_warning();
  }
}

package CheckPduHealth::Sentry4::Components::PowerSubsystem::Branch;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'branch %s status is %s state is %s',
      $self->{st4BranchLabel}, $self->{st4BranchStatus}, $self->{st4BranchState});
  if ($self->{st4BranchState} eq 'on') {
    if ($self->{st4BranchStatus} =~ /normal|disabled|purged|reading|settle/) {
    } elsif ($self->{st4BranchStatus} =~ /lowWarning|highWarning/) {
      $self->add_warning();
    } elsif ($self->{st4BranchStatus} =~ /readError|pwrError|breakerTripped|fuseBlown|lowAlarm|highAlarm|alarm|underLimit|overLimit|nvmFail|profileError|conflict/) {
      $self->add_critical();
    } elsif ($self->{st4BranchStatus} =~ /notFound|lost|noComm|/) {
      $self->add_unknown();
    }
  }
}

package CheckPduHealth::Sentry4::Components::PowerSubsystem::Outlet;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'outlet %s status is %s state is %s',
      $self->{st4OutletName}, $self->{st4OutletStatus}, $self->{st4OutletState});
  if ($self->{st4OutletState} eq 'on') {
    if ($self->{st4OutletStatus} =~ /normal|disabled|purged|reading|settle/) {
    } elsif ($self->{st4OutletStatus} =~ /lowWarning|highWarning/) {
      $self->add_warning();
    } elsif ($self->{st4OutletStatus} =~ /readError|pwrError|breakerTripped|fuseBlown|lowAlarm|highAlarm|alarm|underLimit|overLimit|nvmFail|profileError|conflict/) {
      $self->add_critical();
    } elsif ($self->{st4OutletStatus} =~ /notFound|lost|noComm|/) {
      $self->add_unknown();
    }
  }
}

