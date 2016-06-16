libexec_SCRIPTS=check_pdu_health
GL_MODULES=\
  ../GLPlugin/lib/Monitoring/GLPlugin/Commandline/Getopt.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/Commandline.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/Item.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/TableItem.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/CSF.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/Item.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/TableItem.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/DAMOCLESMIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/MIB2MIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/SNMPFRAMEWORKMIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/PDU2MIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/SENTRY3MIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/SENTRY4MIB.pm \
  ../GLPlugin/lib/Monitoring/GLPlugin/SNMP/MibsAndOids/POWERNETMIB.pm
EXTRA_MODULES=\
  Classes/HWG/Damocles/Components/SensorSubsystem.pm \
  Classes/HWG/Damocles/Components/PowerSubsystem.pm \
  Classes/HWG/Damocles.pm \
  Classes/HWG.pm \
  Classes/APC/Powermib/ATS/Components/BatterySubsystem.pm \
  Classes/APC/Powermib/ATS/Components/EnvironmentalSubsystem.pm \
  Classes/APC/Powermib/ATS.pm \
  Classes/APC/Powermib.pm \
  Classes/APC.pm \
  Classes/Sentry4/Components/EnvironmentalSubsystem.pm \
  Classes/Sentry4/Components/PowerSubsystem.pm \
  Classes/Sentry4.pm \
  Classes/Sentry3/Components/EnvironmentalSubsystem.pm \
  Classes/Sentry3/Components/PowerSubsystem.pm \
  Classes/Sentry3.pm \
  Classes/Raritan/Components/SensorSubsystem.pm \
  Classes/Raritan.pm \
  Classes/Device.pm

SED=/bin/sed
GREP=/bin/grep
CAT=/bin/cat
ECHO=/bin/echo
if DISABLE_STANDALONE
STANDALONE = no
else
STANDALONE = yes
endif

SUFFIXES = .pl .pm .sh

VPATH=$(top_srcdir) $(top_srcdir)/plugins-scripts $(top_srcdir)/plugins-scripts/t

EXTRA_DIST=$(libexec_SCRIPTS).pl $(EXTRA_MODULES) $(GL_MODULES)

CLEANFILES=$(libexec_SCRIPTS)

AM_INSTALL_PROGRAM_FLAGS=@INSTALL_OPTS@

.pm :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

.pl :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

.sh :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

$(libexec_SCRIPTS) : $(EXTRA_DIST)
	$(ECHO) "#! #PERL# -w" | $(AWK) -f ./subst > $@
	$(ECHO) "# nagios: -epn" >> $@
	$(ECHO) >> $@
	if [ "${STANDALONE}" == "yes" ]; then \
		$(ECHO) i am standalone; \
		for m in ${GL_MODULES}; do \
			$(SED) -e 's/^1;//g' < $$m | $(SED) -e '/^__END__/,$$d' | $(AWK) -f ./subst >> $@; \
		done \
	fi
	for m in ${EXTRA_MODULES}; do \
		$(SED) -e 's/^1;//g' < $$m | $(SED) -e '/^__END__/,$$d' | $(AWK) -f ./subst >> $@; \
	done
	$(ECHO) "package main;" >> $@
	$(CAT) $(libexec_SCRIPTS).pl | $(AWK) -f ./subst >> $@
	chmod +x $@

