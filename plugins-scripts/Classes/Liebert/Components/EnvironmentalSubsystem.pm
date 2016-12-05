package Classes::Liebert::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('LIEBERT-GP-PDU-MIB', [
    ['measurements', 'lgpPduAuxMeasTable', 'Classes::Liebert::Components::EnvironmentalSubsystem::Measurement'],
  ]);
}


package Classes::Liebert::Components::EnvironmentalSubsystem::Measurement;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  bless $self, 'Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementTemperature'
      if $self->{lgpPduAuxMeasType} eq 'temperature';
  bless $self, 'Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementHumidity'
      if $self->{lgpPduAuxMeasType} eq 'humidity';
  bless $self, 'Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementDoorclosure'
      if $self->{lgpPduAuxMeasType} eq 'door-closure';
  bless $self, 'Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementContactclosure'
      if $self->{lgpPduAuxMeasType} eq 'contact-closure';
  $self->finish() if ref($self) ne 'Classes::Liebert::Components::EnvironmentalSubsystem::Measurement';
}


package Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementTemperature;
our @ISA = qw(Classes::Liebert::Components::EnvironmentalSubsystem::Measurement);

sub finish {
  my ($self) = @_;
  foreach (qw(lgpPduAuxMeasTempDegF lgpPduAuxMeasTempThrshldUndrAlmDegF lgpPduAuxMeasTempThrshldOvrAlmDegF
      lgpPduAuxMeasTempThrshldUndrWarnDegF lgpPduAuxMeasTempThrshldOvrWarnDegF lgpPduAuxMeasTempDegC
      lgpPduAuxMeasTempThrshldUndrAlmDegC lgpPduAuxMeasTempThrshldOvrAlmDegC
      lgpPduAuxMeasTempThrshldUndrWarnDegC lgpPduAuxMeasTempThrshldOvrWarnDegC)) {
    if (exists $self->{$_} && defined $self->{$_}) {
      $self->{$_} /= 10.0;
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s says %.2fC',
      $self->{lgpPduAuxMeasType}, $self->{lgpPduAuxMeasSensorSysAssignLabel},
      $self->{lgpPduAuxMeasTempDegC}
  );
  $self->set_thresholds(metric => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      warning => $self->{lgpPduAuxMeasTempThrshldUndrWarnDegC}.':'.$self->{lgpPduAuxMeasTempThrshldOvrWarnDegC},
      critical => $self->{lgpPduAuxMeasTempThrshldUndrAlmDegC}.':'.$self->{lgpPduAuxMeasTempThrshldOvrAlmDegC},
  );
  $self->add_message($self->check_thresholds(metric => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      value => $self->{lgpPduAuxMeasTempDegC},
  ));
  if ($self->check_messages() == 1) {
    $self->add_warning(sprintf 'outside of [%.2f%%..%.2f%%]',
        $self->{lgpPduAuxMeasTempThrshldUndrWarnDegC}, $self->{lgpPduAuxMeasTempThrshldOvrWarnDegC}
    );
  } elsif ($self->check_messages() == 2) {
    $self->add_critical(sprintf 'outside of [%.2f%%..%.2f%%]',
        $self->{lgpPduAuxMeasTempThrshldUndrAlmDegC}, $self->{lgpPduAuxMeasTempThrshldOvrAlmDegC}
    );
  }
  $self->add_perfdata(label => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      value => $self->{lgpPduAuxMeasTempDegC},
  );
}

package Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementHumidity;
our @ISA = qw(Classes::Liebert::Components::EnvironmentalSubsystem::Measurement);

sub finish {
  my ($self) = @_;
  foreach (qw(lgpPduAuxMeasHum lgpPduAuxMeasHumThrshldUndrAlm lgpPduAuxMeasHumThrshldOvrAlm
      lgpPduAuxMeasHumThrshldUndrWarn lgpPduAuxMeasHumThrshldOvrWarn)) {
    if (exists $self->{$_} && defined $self->{$_}) {
      $self->{$_} /= 10.0;
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s says %.2f%%',
      $self->{lgpPduAuxMeasType}, $self->{lgpPduAuxMeasSensorSysAssignLabel},
      $self->{lgpPduAuxMeasHum}
  );
  $self->set_thresholds(metric => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      warning => $self->{lgpPduAuxMeasHumThrshldUndrWarn}.':'.$self->{lgpPduAuxMeasHumThrshldOvrWarn},
      critical => $self->{lgpPduAuxMeasHumThrshldUndrAlm}.':'.$self->{lgpPduAuxMeasHumThrshldOvrAlm},
  );
  $self->add_message($self->check_thresholds(metric => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      value => $self->{lgpPduAuxMeasHum},
  ));
  if ($self->check_messages() == 1) {
    $self->add_warning(sprintf 'outside of [%.2f%%..%.2f%%]',
        $self->{lgpPduAuxMeasHumThrshldUndrWarn}, $self->{lgpPduAuxMeasHumThrshldOvrWarn}
    );
  } elsif ($self->check_messages() == 2) {
    $self->add_critical(sprintf 'outside of [%.2f%%..%.2f%%]',
        $self->{lgpPduAuxMeasHumThrshldUndrWarn}, $self->{lgpPduAuxMeasHumThrshldOvrWarn}
    );
  }
  $self->add_perfdata(label => $self->{lgpPduAuxMeasSensorSysAssignLabel},
      value => $self->{lgpPduAuxMeasHum},
      uom => '%',
  );
}


package Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementDoorclosure;
our @ISA = qw(Classes::Liebert::Components::EnvironmentalSubsystem::Measurement);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s says %s (%s)',
      $self->{lgpPduAuxMeasType}, $self->{lgpPduAuxMeasSensorSysAssignLabel},
      $self->{lgpPduAuxMeasDrClosureState}, $self->{lgpPduAuxMeasDrClosureConfig},
  );
  if ($self->{lgpPduAuxMeasDrClosureConfig} eq 'alarm-when-open') {
    if ($self->{lgpPduAuxMeasDrClosureState} eq 'open') {
      $self->add_critical();
    } elsif ($self->{lgpPduAuxMeasDrClosureState} eq 'not-specified') {
      $self->add_unknown();
    }
  }
}


package Classes::Liebert::Components::EnvironmentalSubsystem::MeasurementContactclosure;
our @ISA = qw(Classes::Liebert::Components::EnvironmentalSubsystem::Measurement);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s says %s (%s)',
      $self->{lgpPduAuxMeasType}, $self->{lgpPduAuxMeasSensorSysAssignLabel},
      $self->{lgpPduAuxMeasCntctClosureState}, $self->{lgpPduAuxMeasCntctClosureConfig},
  );
  if ($self->{lgpPduAuxMeasCntctClosureConfig} eq 'alarm-when-open') {
    if ($self->{lgpPduAuxMeasCntctClosureState} eq 'open') {
      $self->add_critical();
    } elsif ($self->{lgpPduAuxMeasCntctClosureState} eq 'not-specified') {
      $self->add_unknown();
    }
  } elsif ($self->{lgpPduAuxMeasCntctClosureConfig} eq 'alarm-when-closed') {
    if ($self->{lgpPduAuxMeasCntctClosureState} eq 'closed') {
      $self->add_critical();
    } elsif ($self->{lgpPduAuxMeasCntctClosureState} eq 'not-specified') {
      $self->add_unknown();
    }
  }
}

