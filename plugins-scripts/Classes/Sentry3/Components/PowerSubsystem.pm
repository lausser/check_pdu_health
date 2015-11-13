package Classes::Sentry3::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('Sentry3-MIB', qw(
      towerStatus 
  ));
  $self->get_snmp_tables('Sentry3-MIB', [
    ['towers', 'towerTable', 'Classes::Sentry3::Components::PowerSubsystem::Tower'],
    ['infeeds', 'infeedTable', 'Classes::Sentry3::Components::PowerSubsystem::Infeed'],
    ['outlets', 'outletTable', 'Classes::Sentry3::Components::PowerSubsystem::Outlet'],
    ['branches', 'branchTable', 'Classes::Sentry3::Components::PowerSubsystem::Branch'],
  ]);
  foreach my $tower (@{$self->{towers}}) {
    foreach my $infeed (@{$self->{infeeds}}) {
      foreach my $outlet (@{$self->{outlets}}) {
        push(@{$infeed->{outlets}}, $outlet) if $outlet->{indices}->[0] == $infeed->{indices}->[0] && $outlet->{indices}->[1] == $infeed->{indices}->[1];
      }
      push(@{$tower->{infeeds}}, $infeed) if $infeed->{indices}->[0] == $tower->{indices}->[0];
    }
  }
  delete $self->{infeeds};
  delete $self->{outlets};
}

package Classes::Sentry3::Components::PowerSubsystem::Tower;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{infeeds} = [];
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'tower %s status is %s',
      $self->{towerName}, $self->{towerStatus});
  if ($self->{towerStatus} eq 'noComm') {
    $self->add_unknown();
  } elsif ($self->{towerStatus} eq 'normal') {
    $self->add_ok(sprintf 'tower %s with %d input feeds',
        $self->{towerName}, scalar(@{$self->{infeeds}}));
  } else {
    $self->add_critical();
  }
  foreach my $infeed (@{$self->{infeeds}}) {
    $infeed->check();
  }
}


package Classes::Sentry3::Components::PowerSubsystem::Infeed;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  $self->{outlets} = [];
}

sub check {
  my $self = shift;
  $self->{infeedLoadValue} /= 100;
  $self->add_info(sprintf 'input feed %s status is %s',
      $self->{infeedName}, $self->{infeedStatus});
  if ($self->{infeedStatus} eq 'on') {
    $self->add_ok(sprintf 'input feed %s with %d outlets',
        $self->{infeedName}, scalar(@{$self->{outlets}}));
    if ($self->{infeedLoadStatus} eq 'normal') {
    } else {
      $self->add_warning();
    }
  } else {
    $self->add_warning();
  }
  $self->add_perfdata(
      label => 'infeed_'.$self->{infeedName}.'_amps',
      value => $self->{infeedLoadValue},
      critical => $self->{infeedLoadHighThresh},
      max => $self->{infeedCapacity},
  ) if $self->{infeedLoadValue} >= 0;
  $self->add_perfdata(
      label => 'infeed_'.$self->{infeedName}.'_watt',
      value => $self->{infeedPower},
  ) if $self->{infeedPower} >= 0;
  $self->add_perfdata(
      label => 'infeed_'.$self->{infeedName}.'_apparent_watt',
      value => $self->{infeedApparentPower},
  ) if $self->{infeedApparentPower} >= 0;
  foreach my $outlet (@{$self->{outlets}}) {
    $outlet->check();
  }
}


package Classes::Sentry3::Components::PowerSubsystem::Outlet;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->{outletLoadValue} /= 100;
  $self->add_info(sprintf 'outlet %s status is %s',
      $self->{outletName}, $self->{outletStatus});
  if ($self->{outletStatus} eq 'on') {
    if ($self->{outletLoadStatus} eq 'normal') {
    } else {
      $self->add_warning();
    }
  } else {
    $self->add_warning();
  }
}

package Classes::Sentry3::Components::PowerSubsystem::Branch;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

