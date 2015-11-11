package Classes::Sentry4;
our @ISA = qw(Classes::Device);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Sentry4::Components::EnvironmentalSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } elsif ($self->mode =~ /device::battery::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Sentry4::Components::InletSensorSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } else {
    $self->no_such_mode();
  }
}

