package Classes::Vertiv::V5::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('VERTIV-V5-MIB', qw(
      productTitle productVersion productFriendlyName
      deviceCount temperatureUnits
      productModelNumber productSerialNumber productPlatform
      productAlarmCount productWarnCount
      productManufacturer));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s %s has %d warnings and %d critical alarms',
      $self->{productTitle}, $self->{productFriendlyName},
      $self->{productWarnCount}, $self->{productAlarmCount});
  if ($self->{productAlarmCount} > 0) {
    $self->add_critical();
  } elsif ($self->{productWarnCount} > 0) {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
}

