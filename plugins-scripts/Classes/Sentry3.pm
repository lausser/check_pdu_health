package Classes::Sentry3;
our @ISA = qw(Classes::Device);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Sentry3::Components::EnvironmentalSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } elsif ($self->mode =~ /device::power::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Sentry3::Components::PowerSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } else {
    $self->no_such_mode();
  }
}

