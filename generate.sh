#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function help {
   echo "Usage : ./generate.sh [host] [proxy url]"
   echo "Example : ./generate.sh foo.bar.com http://bar.foo.com:81"
}
function pause {
    echo "Press enter to continue."
    read a
}

if [ -z "$1" ]
  then
    echo "No host supplied"
    help
    exit
fi
if [ -z "$2" ]
  then
    echo "No proxy supplied"
    help
    exit
fi

host=$1
proxy=$2
www=/var/www/$host
http=/etc/nginx/sites-available/http.$host
ehttp=/etc/nginx/sites-enabled/http.$host
https=/etc/nginx/sites-available/https.$host
ehttps=/etc/nginx/sites-enabled/https.$host
dhparam=/etc/nginx/dhparam.pem


cat <<EOF
www folder : $www
http sites-available : $http
http sites-enabled : $ehttp
https sites-available : $https
https sites-enabled : $ehttp
dhparam : $dhparam

Warning, this script will reload multiple times nginx, use Ctrl-C now to cancel script
EOF
pause

echo creating www folder $www
mkdir -p $www
echo done

echo cleaning existing site-enabled
rm $ehttp 2> /dev/null
rm $ehttps 2> /dev/null
service nginx reload
echo done


if [ -f $dhparam ];
then
   echo "dhparam exist, skipping"
else
   echo creating $dhparam
   openssl dhparam -out $dhparam 4096
   echo done
fi



echo creating $http

cat <<EOF > $http
server { 
    listen 80; 
    listen [::]:80; 
    server_name $host; 
    location /.well-known { 
            alias /var/www/$host/.well-known; 
    } 
    location / { 
        return 301 https://$host; 
    } 
} 
EOF
echo done

echo creating $https
cat <<EOF > $https
server {
    listen 443 ssl; 
    listen [::]:443 ssl; 
    server_name $host; 
    ssl_certificate /etc/letsencrypt/live/$host/fullchain.pem; 
    ssl_certificate_key /etc/letsencrypt/live/$host/privkey.pem; 
    ssl_stapling on; 
    ssl_stapling_verify on; 
    ssl_dhparam $dhparam; 
    ssl_protocols TLSv1.2; 
    add_header Strict-Transport-Security max-age=31536000; 
    location /.well-known { 
            alias /var/www/$host/.well-known; 
    } 
    location / { 
        proxy_pass  $proxy; 
        proxy_set_header X-Real-IP  \$remote_addr; 
        proxy_set_header X-Forwarded-For \$remote_addr; 
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Host \$host; 
        proxy_set_header X-Forwarded-Proto \$scheme; 
    } 
} 
EOF
echo done

echo activating http website
ln -s $http $ehttp
service nginx reload
echo done

pause

echo request certificate
certbot certonly --webroot -w $www -d $host
echo done

echo activating https website
ln -s $https $ehttps
service nginx reload
echo done
