package CheckPduHealth::Raritan;
our @ISA = qw(CheckPduHealth::Device);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Raritan::Components::ExternalSensorSubsystem');
    $self->reduce_messages_short("hardware working fine");
  } elsif ($self->mode =~ /device::power::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckPduHealth::Raritan::Components::InletSensorSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } else {
    $self->no_such_mode();
  }
}

