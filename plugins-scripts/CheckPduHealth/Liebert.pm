package CheckPduHealth::Liebert;
our @ISA = qw(CheckPduHealth::Device);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Liebert::Components::EnvironmentalSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } elsif ($self->mode =~ /device::power::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Liebert::Components::PowerSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } else {
    $self->no_such_mode();
  }
}

