package Classes::APC::Powermib::ATS::Components::BatterySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use POSIX qw(mktime);

sub init {
  my $self = shift;
  $self->get_snmp_objects('PowerNet-MIB', (qw(atsCalibrationNumInputs
      atsCalibrationNumInputPhases atsCalibrationNumOutputs atsCalibrationNumOutputPhases 
      atsNumInputs atsNumOutputs atsOutputBankTableSize
  )));
  $self->get_snmp_tables("PowerNet-MIB", [
      #["alarms", "upsAlarmTable", "Classes::Socomec::Netvision::Components::EnvironmentalSubsystem::Alarm"],
      ["calibrationinputphases", "atsCalibrationInputPhaseTable", "Monitoring::GLPlugin::SNMP::TableItem"],
      ["powersupplyvoltagess", "atsCalibrationPowerSupplyVoltageTable", "Monitoring::GLPlugin::SNMP::TableItem"],
      ["calibrationoutputs", "atsCalibrationOutputTable", "Monitoring::GLPlugin::SNMP::TableItem"],
      ["atsConfigBankTable", "atsConfigBankTable", "Monitoring::GLPlugin::SNMP::TableItem"],
      ["atsConfigPhaseTable", "atsConfigPhaseTable", "Monitoring::GLPlugin::SNMP::TableItem"],
# atsConfigPhaseTable -> bezug zo atsOutputPhaseTable
      ["atsInputTable", "atsInputTable", "Monitoring::GLPlugin::SNMP::TableItem"],
# atsInputFrequency atsInputName
      ["atsInputPhaseTable", "atsInputPhaseTable", "Classes::APC::Powermib::ATS::Components::BatterySubsystem::Input"],
# atsInputVoltage, atsInputMaxVoltage atsInputMinVoltage , -1 heisst not avail
# atsInputCurrent atsInputMinCurrent atsInputMaxCurrent
# atsInputPower atsInputMaxPower atsInputMinPower
      ["atsOutputTable", "atsOutputTable", "Monitoring::GLPlugin::SNMP::TableItem"],
      ["atsOutputPhaseTable", "atsOutputPhaseTable", "Classes::APC::Powermib::ATS::Components::BatterySubsystem::Output"],
#atsOutputPercentLoad atsOutputPercentPower
#atsOutputCurrent atsOutputLoad atsOutputPower atsOutputVoltage
      ["atsOutputBankTable", "atsOutputBankTable", "Monitoring::GLPlugin::SNMP::TableItem"],
  ]);

}


package Classes::APC::Powermib::ATS::Components::BatterySubsystem::InOutput;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


sub check {
  my $self = shift;
  my $info = undef;
  foreach my $metric (@{$self->{metrics}}) {
    next if $self->{'ats'.$self->{prefix}.$metric} == -1;
    my $critical = undef;
    my $critical_min = (exists $self->{'ats'.$self->{prefix}.'Min'.$metric} && $self->{'ats'.$self->{prefix}.'Min'.$metric} != -1) ?
        $self->{'ats'.$self->{prefix}.'Min'.$metric} : undef;
    my $critical_max = (exists $self->{'ats'.$self->{prefix}.'Max'.$metric} && $self->{'ats'.$self->{prefix}.'Max'.$metric} != -1) ?
        $self->{'ats'.$self->{prefix}.'Max'.$metric} : undef;
    if (defined $critical_min) {
      $critical = $critical_min.':';
    }
    if (defined $critical_max) {
      $critical = $critical ? $critical.$critical_max : $critical_max;
    }
    $self->set_thresholds(
        metric => $self->{prefix}.$self->{serial}.'_'.$metric,
        critical => $critical
    ) if defined $critical;
    $self->add_perfdata(
        label => lc $self->{prefix}.$self->{serial}.'_'.$metric,
        value => $self->{'ats'.$self->{prefix}.$metric},
        uom => lc $metric =~ /percent/ ? '%' : undef,
    ) if defined $self->{'ats'.$self->{prefix}.$metric};
  }
  if (! $self->check_messages()) {
    $self->add_ok("hardware working fine");
  }
}

package Classes::APC::Powermib::ATS::Components::BatterySubsystem::Input;
our @ISA = qw(Classes::APC::Powermib::ATS::Components::BatterySubsystem::InOutput);
use strict;

sub finish {
  my $self = shift;
  $self->{metrics} = ['Current', 'Power', 'Voltage'];
  $self->{prefix} = 'Input';
  $self->{serial} = $self->{flat_indices};
  $self->{serial} =~ s/\..+$//g;
}

package Classes::APC::Powermib::ATS::Components::BatterySubsystem::Output;
our @ISA = qw(Classes::APC::Powermib::ATS::Components::BatterySubsystem::InOutput);
use strict;

sub finish {
  my $self = shift;
  $self->{metrics} = ['Current', 'Power', 'Voltage', 'Load', 'PercentLoad', 'PercentPower'];
  $self->{prefix} = 'Output';
  $self->{serial} = '';
}


