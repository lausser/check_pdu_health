package CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem;
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
      ["atsInputPhaseTable", "atsInputPhaseTable", "CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::Input"],
      ["atsOutputPhaseTable", "atsOutputPhaseTable", "CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::Output"],
  ]);
}

sub check {
  my $self = shift;
  $self->SUPER::check();
  $self->reduce_messages();
}


package CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::InOutput;
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
    $critical = 90 if ! defined $critical && $metric =~ /percent/i;
    $self->set_thresholds(
        metric => lc $self->{prefix}.$self->{serial}.'_'.$metric,
        warning => $critical,
        critical => $critical
    ) if defined $critical;
    if (my $level = $self->check_thresholds(
        metric => lc $self->{prefix}.$self->{serial}.'_'.$metric,
        value => $self->{'ats'.$self->{prefix}.$metric})) {
      $self->add_message($level,
          sprintf "%s value %s is outside of range %s", $metric,
          $self->{'ats'.$self->{prefix}.$metric},
          $level == 1 ?
              ($self->get_thresholds(
                  metric => lc $self->{prefix}.$self->{serial}.'_'.$metric)
              )[0]
              :
              ($self->get_thresholds(
                  metric => lc $self->{prefix}.$self->{serial}.'_'.$metric)
              )[1]
      );
    }
    $self->add_perfdata(
        label => lc $self->{prefix}.$self->{serial}.'_'.$metric,
        value => $self->{'ats'.$self->{prefix}.$metric},
        uom => ($metric =~ /percent/i) ? '%' : undef,
    ) if defined $self->{'ats'.$self->{prefix}.$metric};
  }
}

package CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::Input;
our @ISA = qw(CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::InOutput);
use strict;

sub finish {
  my $self = shift;
  $self->{metrics} = ['Current', 'Power', 'Voltage'];
  $self->{prefix} = 'Input';
  $self->{serial} = $self->{flat_indices};
  $self->{serial} =~ s/\..+$//g;
}

package CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::Output;
our @ISA = qw(CheckPduHealth::APC::Powermib::ATS::Components::BatterySubsystem::InOutput);
use strict;

sub finish {
  my $self = shift;
  $self->{metrics} = ['Current', 'Power', 'Voltage', 'Load', 'PercentLoad', 'PercentPower'];
  $self->{prefix} = 'Output';
  $self->{serial} = '';
}


