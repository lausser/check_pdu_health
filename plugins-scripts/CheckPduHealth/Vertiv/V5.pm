package CheckPduHealth::Vertiv::V5;
our @ISA = qw(CheckPduHealth::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::power/) {
    $self->analyze_and_check_battery_subsystem('CheckPduHealth::Vertiv::V5::Components::PowerSubsystem');
  } elsif ($self->mode =~ /device::hardware/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Vertiv::V5::Components::EnvironmentalSubsystem');
  } else {
    $self->no_such_mode();
  }
}

