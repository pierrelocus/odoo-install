# odoo-install
Install Odoo on a VPS (Ubuntu 20.04)

Usage: ./odoo_install.sh \<domain\> \<admin pass\> <external git? ''> <sleep?30>

Just launch the command giving the domain name on which the ssl certificate has to be installed,

an Admin password for the odoo.conf file

External Git if your odoo installation depends on third parties (will be cloned and added in the addons-path)

Sleep is default 30, is the time the program will wait when it generates you a RSA key to add in your github (for cloning purposes).

Have fun
