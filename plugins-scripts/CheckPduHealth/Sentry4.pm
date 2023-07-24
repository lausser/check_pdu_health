package CheckPduHealth::Sentry4;
our @ISA = qw(CheckPduHealth::Device);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Sentry4::Components::EnvironmentalSubsystem');
  } elsif ($self->mode =~ /device::power::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Sentry4::Components::PowerSubsystem');
  } else {
    $self->no_such_mode();
  }
  if (! $self->check_messages()) {
    $self->add_ok('hardware working fine');
  }
}

