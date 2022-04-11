#!/usr/bin/bash

DOMAIN_NAME="$1"
ADMIN_PASS="$2"
GITHUB_ADD="$3"
SLEEP="$4"

if [ -z "$2" ]
then
	echo "Usage: ./odoo_install.sh <domain> <admin pass> <external git?''> <sleep?30>"
	exit 1
fi

# Update system
sudo apt update
sudo apt upgrade -y

ssh-keygen -t rsa -b 4096
echo "raf"
echo ""
echo ""
cat ~/.ssh/id_rsa.pub

if [ -z $SLEEP ]
then
  sleep 30
else
  sleep $SLEEP
fi

# installing python stuff

sudo apt install -y python3-pip python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev
# Install postgresql
sudo apt install postgresql postgresql-client -y

sudo pg_ctlcluster 12 main start

sudo -u postgres createuser -s $USER
createdb $USER

sudo service postgresql restart
# Allow port 8069 for testing?
# sudo ufw allow 8069

# Installing odoo

sudo su root -c "wget -O - https://nightly.odoo.com/odoo.key | apt-key add -"
sudo su root -c "echo 'deb http://nightly.odoo.com/14.0/nightly/deb/ ./' >> /etc/apt/sources.list.d/odoo.list"

sudo apt update && sudo apt install odoo -y

echo "Odoo installed !"

git clone git@github.com:odoo/enterprise.git /home/ubuntu/enterprise

echo "Enterprise cloned !"

GITHUB_EXTERNAL=""
if [ ! -z $GITHUB_ADD ]
then
  mkdir -p /home/ubuntu/custom
  git clone $GITHUB_ADD /home/ubuntu/custom/custom
  GITHUB_EXTERNAL=",/home/ubuntu/custom/custom"
fi

# Installation des packages importants
sudo apt install git nginx snapd -y
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot


sudo chown -R ubuntu:ubuntu /home/ubuntu
sudo -u root unlink /etc/nginx/sites-enabled/default
sudo -u root touch /etc/nginx/sites-available/odoo

sudo su root -c "echo '#odoo server
upstream odoo {
 server 127.0.0.1:8069;
}
upstream odoochat {
 server 127.0.0.1:8072;
}

server {
    server_name $DOMAIN_NAME;

 proxy_read_timeout 720s;
 proxy_connect_timeout 720s;
 proxy_send_timeout 720s;

 # Add Headers for odoo proxy mode
 proxy_set_header X-Forwarded-Host \$host;
 proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
 proxy_set_header X-Forwarded-Proto \$scheme;
 proxy_set_header X-Real-IP \$remote_addr;

 # log
 access_log /var/log/nginx/odoo.access.log;
 error_log /var/log/nginx/odoo.error.log;

 # Redirect longpoll requests to odoo longpolling port
 location /longpolling {
 proxy_pass http://odoochat;
 }

 # Redirect requests to odoo backend server
 location / {
   proxy_redirect off;
   proxy_pass http://odoo;
 }

 # common gzip
 gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
 gzip on;
}
server {
    listen 80; # Add by LOP
    server_name $DOMAIN_NAME;
    rewrite ^(.*) https://\$host\$1 permanent; # uncomment
}

' > /etc/nginx/sites-available/odoo"

sudo su root -c "ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo"

sudo su root -c "echo '[options]
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/home/ubuntu/enterprise$GITHUB_EXTERNAL
admin_passwd = $ADMIN_PASS
csv_internal_sep = ,
data_dir = /var/lib/odoo/.local/share/Odoo
db_host = False
db_maxconn = 64
db_name = False
db_password = False
db_port = False
db_sslmode = prefer
db_template = template0
db_user = odoo
dbfilter =
demo = {}
email_from = False
geoip_database = /usr/share/GeoIP/GeoLite2-City.mmdb
http_enable = True
http_interface = 
http_port = 8069
import_partial = 
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 300
limit_time_real = 900
limit_time_real_cron = -1
list_db = True
log_db = True
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = /var/log/odoo/odoo-server.log
longpolling_port = 8072
max_cron_threads = 1
osv_memory_age_limit = False
osv_memory_count_limit = False
pg_path = 
pidfile = 
proxy_mode = True
reportgz = False
screencasts = 
screenshots = /tmp/odoo_tests
server_wide_modules = base,web
smtp_password = False
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
smtp_user = False
syslog = False
test_enable = False
test_file = 
test_tags = None
transient_age_limit = 1.0
translate_modules = ['all']
unaccent = False
upgrade_path = 
without_demo = False
workers = 3' > /etc/odoo/odoo.conf"

sudo /etc/init.d/odoo restart
sudo certbot --nginx -d $DOMAIN_NAME
sudo /etc/init.d/nginx restart


# WKHTML
echo "installing wkhtml"
cd ~
sudo apt-get install libfontenc1 xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils openssl build-essential libssl-dev libxrender-dev git-core libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig -y
wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo apt-get -f install

echo "end"

echo "last packet needed with pip"
sudo pip3 install num2words
