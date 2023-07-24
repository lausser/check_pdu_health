package CheckPduHealth::Liebert::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('LIEBERT-GP-PDU-MIB', [
    ['pdus', 'lgpPduTable', 'CheckPduHealth::Liebert::Components::PowerSubsystem::PDU'],
    ['powersources', 'lgpPduPsTable', 'CheckPduHealth::Liebert::Components::PowerSubsystem::Powersource'],
  ]);


#  foreach (qw(unit cord line phase ocp branch)) {
#    $self->merge($_.'monitors', $_.'configs', $_.'eventconfigs');
#  }
#  $self->merge(qw(outletmonitors outletconfigs outleteventconfigs outletcontrols));
#
#  foreach my $unit (@{$self->{unitmonitors}}) {
#    foreach my $cord (@{$self->{cordmonitors}}) {
#      push(@{$unit->{cords}}, $cord) if $cord->{indices}->[0] == $unit->{indices}->[0];
#    }
#  }
#  foreach my $cord (@{$self->{cordmonitors}}) {
#    foreach my $itemname (qw(line phase ocp branch outlet)) {
#      foreach my $item (@{$self->{$itemname.'monitors'}}) {
#        push(@{$cord->{$itemname.'s'}}, $item) if $item->{indices}->[0] == $cord->{indices}->[0] && $item->{indices}->[1] == $cord->{indices}->[1];
#      }
#    }
#  }
}

sub xcheck {
  my $self = shift;
  $self->add_info('check units');
  foreach my $unit (@{$self->{unitmonitors}}) {
    $unit->check();
  }
}


package CheckPduHealth::Liebert::Components::PowerSubsystem::PDU;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{label} = $self->{lgpPduEntryUsrLabel} || $self->{lgpPduEntrySysAssignLabel};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'pdu %s status is %s',
      $self->{label}, $self->{lgpPduEntrySysStatus});
  if ($self->{lgpPduEntrySysStatus} =~ /(normalOperation)|(startUp)/) {
    $self->add_ok();
  } elsif ($self->{lgpPduEntrySysStatus} =~ /(normalWithWarning)/) {
    $self->add_warning();
  } elsif ($self->{lgpPduEntrySysStatus} =~ /(normalWithAlarm)/) {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
}


package CheckPduHealth::Liebert::Components::PowerSubsystem::Powersource;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{label} = $self->{lgpPduPsEntrySysAssignLabel};
  $self->{lgpPduPsEntryEcInputRated} /= 10.0;
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s power source %s total input power is %.2fW, neutral current is %.2fA',
      $self->{lgpPduPsEntryWiringType}, $self->{label}, $self->{lgpPduPsEntryPwrTotal},
      $self->{lgpPduPsEntryEcNeutral});
  $self->set_thresholds(metric => $self->{label},
      warning => $self->{lgpPduPsEntryEcNeutralThrshldOvrWarn},
      critical => $self->{lgpPduPsEntryEcNeutralThrshldOvrAlarm},
  );
  $self->add_perfdata(label => $self->{label},
      value => 100 * $self->{lgpPduPsEntryEcNeutral} / $self->{lgpPduPsEntryEcInputRated},
      uom => '%',
  );
}
