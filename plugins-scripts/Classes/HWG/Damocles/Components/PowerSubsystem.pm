package Classes::HWG::Damocles::Components::PowerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('DAMOCLES-MIB', [
      ['inputs', 'inpTable', 'Classes::HWG::Damocles::Components::PowerSubsystem::Input'],
      ['outputs', 'outTable', 'Classes::HWG::Damocles::Components::PowerSubsystem::Output'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->reduce_messages_short(sprintf "checked %d inputs and %d outputs, all of them are ok",
      scalar(@{$self->{inputs}}), scalar(@{$self->{inputs}}));
}

package Classes::HWG::Damocles::Components::PowerSubsystem::Input;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "input %s is %s, alarm is %s and %s, counted %s pulses",
      $self->{inpName}, $self->{inpValue},
      $self->{inpAlarmSetup}, $self->{inpAlarmState},
      $self->{inpCounter});
  if ($self->{inpAlarmState} eq "alarm") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

package Classes::HWG::Damocles::Components::PowerSubsystem::Output;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s %s output %s is %s",
      $self->{outType}, $self->{outMode}, $self->{outName}, $self->{outValue});
  if ($self->{outValue} =~ /alarm/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}



