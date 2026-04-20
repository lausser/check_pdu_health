package CheckPduHealth::APC::Powermib::PDU;
our @ISA = qw(CheckPduHealth::APC::Powermib);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::power/) {
    # Use PowerSubsystem for PDU (not inherited BatterySubsystem from parent)
    $self->analyze_and_check_battery_subsystem(ref($self).'::Components::PowerSubsystem');
  } elsif ($self->mode =~ /device::hardware/) {
    $self->analyze_and_check_environmental_subsystem(ref($self).'::Components::EnvironmentalSubsystem');
  } else {
    $self->no_such_mode();
  }
}

1;
