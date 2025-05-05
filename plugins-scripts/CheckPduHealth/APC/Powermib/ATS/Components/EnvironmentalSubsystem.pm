package CheckPduHealth::APC::Powermib::ATS::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use POSIX qw(mktime);

sub init {
  my $self = shift;
  $self->get_snmp_objects('PowerNet-MIB', (qw(atsIdentHardwareRev
   atsIdentFirmwareRev atsIdentFirmwareDate atsIdentDateOfManufacture
   atsIdentModelNumber atsIdentSerialNumber atsIdentNominalLineVoltage
   atsIdentNominalLineFrequency atsIdentDeviceRating atsStatusCommStatus
   atsStatusSelectedSource atsStatusRedundancyState atsStatusOverCurrentState
   atsStatus5VPowerSupply atsStatus24VPowerSupply atsStatus24VSourceBPowerSupply
   atsStatusPlus12VPowerSupply atsStatusMinus12VPowerSupply
   atsStatusSwitchStatus atsStatusFrontPanel atsStatusSourceAStatus
   atsStatusSourceBStatus atsStatusPhaseSyncStatus atsStatusVoltageOutStatus
   atsStatusHardwareStatus 
  )));
  # Folgendes trug sich zu im April anno 2025
  # Antwort eines APC-Geraets:
  # .1.3.6.1.4.1.318.1.1.8.5.1.15.0 = INTEGER: 1
  # atsStatusVoltageOutStatus OBJECT-TYPE
  # SYNTAX INTEGER {
  # fail(1),
  # ok(2)
  # }
  # Das Nachbargeraet bringt wie bisher den Wert 2.
  # Wehklagen des Betriebsteams. Man haette die Firmware aktualisiert.
  # .1.3.6.1.4.1.318.1.4.2.4.1.3.1 = STRING: "apc_hw05_aos_712.bin"
  # .1.3.6.1.4.1.318.1.4.2.4.1.3.2 = STRING: "apc_hw05_ats4g_714.bin"
  # .1.3.6.1.4.1.318.1.4.2.4.1.3.3 = STRING: "apc_hw05_bootmon_109.bin"
  # So. Und jetzt stellt sich heraus, dass es ein "Known Issue" bei
  # ats4g_714 gibt.
  # "Voltage out checking is not currently supported; any approach to read the output voltage will always result in reading of voltage present, regardless of its actual status" ist jetzt nicht exakt das beschriebene Szenario, aber es
  # gibt auch noch persoenliches Feedback von APC selbst:
  # "There's a reported error in iod atsStatusVoltageOutStatus, which is the reason why we recommend to use ATSOutputVoltage: .1.3.6.1.4.1.318.1.1.8.5.4.3.1.3 for the meantime. It fails even though there's no failure on the device itself. This has already been raised with our Advanced Technical Team."
  # also frickelt der Lausser und baut eine Sonderlocke ein und stellt das in
  # Rechnung, dass es nur so schnalzt.
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'PowerNet-MIB'}->{'atsExperimentalFirmware1'} = '1.3.6.1.4.1.318.1.4.2.4.1.3.1';
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'PowerNet-MIB'}->{'atsExperimentalFirmware2'} = '1.3.6.1.4.1.318.1.4.2.4.1.3.2';
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'PowerNet-MIB'}->{'atsExperimentalFirmware3'} = '1.3.6.1.4.1.318.1.4.2.4.1.3.3';
  $self->get_snmp_objects('PowerNet-MIB', (qw(atsExperimentalFirmware1
      atsExperimentalFirmware2 atsExperimentalFirmware3)));
  if ($self->{atsExperimentalFirmware1} eq "apc_hw05_ats4g_714.bin" or
      $self->{atsExperimentalFirmware2} eq "apc_hw05_ats4g_714.bin" or
      $self->{atsExperimentalFirmware3} eq "apc_hw05_ats4g_714.bin") {
    $self->get_snmp_tables("PowerNet-MIB", [
      ["outputphases", "atsOutputPhaseTable", "CheckPduHealth::APC::Powermib::ATS::Components::EnvironmentalSubsystem::OutputPhase"],
      #["outputs", "atsOutputTable", "Monitoring::GLPlugin::SNMP::TableItem"],
    ]);
    $self->{atsStatusVoltageOutStatus} = "ok";
  }
}

sub check {
  my $self = shift;
  my $info = undef;
  $self->add_info('checking hardware and self-tests');
  $self->add_info('status is '.$self->{atsStatusHardwareStatus});
  foreach my $item (qw(atsStatus24VPowerSupply atsStatus24VSourceBPowerSupply
      atsStatus5VPowerSupply atsStatusMinus12VPowerSupply atsStatusPlus12VPowerSupply)) {
    next if ! defined $self->{$item};
    $self->add_info(sprintf "%s is %s", $item, $self->{$item});
    if ($self->{$item} ne "atsPowerSupplyOK") {
      $self->add_critical();
    }
  }
  foreach my $item (qw(atsStatusHardwareStatus atsStatusSourceAStatus
      atsStatusSourceBStatus atsStatusSwitchStatus atsStatusVoltageOutStatus)) {
    $self->add_info(sprintf "%s is %s", $item, $self->{$item});
    if ($self->{$item} ne "ok") {
      $self->add_critical();
    }
  }
  foreach my $item (qw(atsStatusRedundancyState)) {
    $self->add_info(sprintf "%s is %s", $item, $self->{$item});
    if ($self->{$item} ne "atsFullyRedundant") {
      $self->add_warning();
    }
  }
  $self->SUPER::check();
  if (! $self->check_messages()) {
    $self->add_ok("hardware working fine");
  }
}


package CheckPduHealth::APC::Powermib::ATS::Components::EnvironmentalSubsystem::OutputPhase;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "output %s with %dV has status %s", $self->{atsOutputPhaseIndex}, $self->{atsOutputVoltage}, $self->{atsOutputPhaseState});
  if ($self->{atsOutputPhaseState} eq "overload") {
    $self->add_critical();
  } elsif ($self->{atsOutputPhaseState} ne "normal") {
    $self->add_warning();
  }
  if ($self->{atsOutputVoltage} eq "-1") {
    # The output voltage in VAC, or -1 if it's unsupported by this ATS
  } elsif (! $self->{atsOutputVoltage}) {
    $self->add_warning();
  }
}

