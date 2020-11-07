#!/bin/sh

json="{ \"value1\" : \"$HOSTALIAS is $HOSTSTATE\", \"value2\" : \" at $LONGDATETIME\", \"value3\" : \"$ICINGA_URL/icingaweb2/monitoring/host/show?host=$HOSTALIAS\" }"

curl -X POST -H "Content-Type: application/json" -k -d "$json" https://maker.ifttt.com/trigger/incinga_alert/with/key/thisisnottherealsecret
