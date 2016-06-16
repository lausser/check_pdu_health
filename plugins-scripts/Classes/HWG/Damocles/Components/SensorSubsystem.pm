package Classes::HWG::Damocles::Components::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('DAMOCLES-MIB', [
      ['sensors', 'sensTable', 'Classes::HWG::Damocles::Components::SensorSubsystem::Sensor'],
      ['sensorsetups', 'sensSetupTable', 'Classes::HWG::Damocles::Components::SensorSubsystem::SensorSetup'],
  ]);
  $self->merge_tables("sensors", "sensorsetups");
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  if (scalar(@{$self->{sensors}})) {
    $self->reduce_messages_short(sprintf "checked %d sensors, all of them are ok",
        scalar(@{$self->{sensors}}));
  } else {
    $self->add_ok("this device does not have any sensors");
  }
}

package Classes::HWG::Damocles::Components::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "sensor %s measures %s, state is %s",
      $self->{sensName}, $self->{sensString}, $self->{sensState});
  if ($self->{sensState} eq "invalid") {
    $self->add_unknown();
  } elsif ($self->{sensState} eq "normal") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my %perfdata = (
    label => 'sensor_'.$self->{sensName},
    value => $self->{sensValue} / 10,
  );
  if (defined $self->{sensLimitMin} and defined $self->{sensLimitMax}) {
    $self->set_thresholds(metric => 'sensor_'.$self->{sensName},
        warning => $self->{sensLimitMin} / 10,
        critical => $self->{sensLimitMax} / 10,
    );
  } elsif (defined $self->{sensLimitMin}) {
    $self->set_thresholds(metric => 'sensor_'.$self->{sensName},
        warning => $self->{sensLimitMin} / 10,
    );
  } elsif (defined $self->{sensLimitMax}) {
    $self->set_thresholds(metric => 'sensor_'.$self->{sensName},
        critical => $self->{sensLimitMax} / 10,
    );
  }
  $perfdata{uom} = "%" if $self->{sensUnit} eq "percent";
  my @thresholds = $self->get_thresholds(metric => 'sensor_'.$self->{sensName});
  if (defined $thresholds[0]) {
    $perfdata{warning} = ($self->get_thresholds(metric => 'sensor_'.$self->{sensName}))[0];
  }
  if (defined $thresholds[1]) {
    $perfdata{critical} = ($self->get_thresholds(metric => 'sensor_'.$self->{sensName}))[1];
  }
  $self->add_perfdata(%perfdata);
}

package Classes::HWG::Damocles::Components::SensorSubsystem::SensorSetup;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);


