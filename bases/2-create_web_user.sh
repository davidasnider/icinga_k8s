#!/usr/bin/bash

#Create the admin ID
# Generate the below password by running
#        php -r 'echo password_hash("whatevertheactualpasswordis", PASSWORD_DEFAULT);'
# on the icinga-web-fpm container, make sure to escape the $ like \$


psql --username ${POSTGRES_USER} icinga_web << EOF
INSERT INTO icingaweb_user (name, active, password_hash) VALUES ('icingaadmin', 1, '\$2y\$10\$fPKs8kjcF1OwsF3r9CdLA.ucN8VguoB9wJx56wld0WQ2EwbDi63iC');
EOF
