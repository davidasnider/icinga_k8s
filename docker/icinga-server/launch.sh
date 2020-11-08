#!/bin/bash

# Setup some defaults before launching Icinga

icinga2 api setup --cn '*.thesniderpad.com'
icinga2 feature enable ido-pgsql

exec "/usr/sbin/icinga2 --no-stack-rlimit daemon -e /var/log/icinga2/icinga2.err -x notice"
