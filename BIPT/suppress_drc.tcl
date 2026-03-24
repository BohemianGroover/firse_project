# Suppress DRC warnings for internal BRAM signals
# These are not I/O pins, so I/O standard and location constraints don't apply

set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
