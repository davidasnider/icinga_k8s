#!/bin/sh

FIXEDSERVICEDESC=$(echo $SERVICEDESC | sed -e 's/ /%20/g')

json="{ \"value1\" : \"$SERVICEDESC on $HOSTALIAS is $SERVICESTATE\", \"value2\" : \" at $LONGDATETIME\", \"value3\" : \"$ICINGA_URL/icingaweb2/monitoring/service/show?host=$HOSTALIAS&service=$FIXEDSERVICEDESC\" }"

curl -X POST -H "Content-Type: application/json" -k -d "$json" https://maker.ifttt.com/trigger/incinga_alert/with/key/thisisnottherealsecret
