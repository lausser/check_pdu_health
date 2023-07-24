package CheckPduHealth::HWG::Damocles;
our @ISA = qw(CheckPduHealth::HWG);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::power/) {
    $self->analyze_and_check_battery_subsystem(ref($self).'::Components::PowerSubsystem');
  } elsif ($self->mode =~ /device::hardware/) {
    $self->analyze_and_check_environmental_subsystem(ref($self).'::Components::SensorSubsystem');
  } else {
    $self->no_such_mode();
  }
}

