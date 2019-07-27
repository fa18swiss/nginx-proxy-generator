#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function help {
   echo "Usage : ./generate.sh [host] [proxy url] [-s (use the staging version to test network)]"
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

staging=""
if [ -n "$3" ]
  then
    if [ "-s" == "$3" ]
      then
        echo "Using staging environment"
        staging="--staging"
    else
        echo "Flag not recognized: $3"
        help
        exit
    fi
fi

host=$1
proxy=$2
www=/var/www/$host
http=/etc/nginx/sites-available/http.$host
ehttp=/etc/nginx/sites-enabled/http.$host
https=/etc/nginx/sites-available/https.$host
ehttps=/etc/nginx/sites-enabled/https.$host
dhparam=/etc/nginx/dhparam.pem
sslconf=/etc/nginx/conf.d/ssl_session_tickets


cat <<EOF
www folder : $www
http sites-available : $http
http sites-enabled : $ehttp
https sites-available : $https
https sites-enabled : $ehttp
dhparam : $dhparam
sslconf : $sslconf

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


echo creating or updating ssl configuration
cat <<EOF > $sslconf
ssl_session_tickets off;
EOF


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
        return 301 https://$host$request_uri;
    }
}
EOF
echo done

echo creating $https
cat <<EOF > $https
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $host;
    ssl_certificate /etc/letsencrypt/live/$host/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$host/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_dhparam $dhparam;
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_stapling on;
    ssl_stapling_verify on;    
    ssl_trusted_certificate /etc/letsencrypt/live/$host/chain.pem;
    add_header Strict-Transport-Security max-age=31536000;
    location /.well-known {
            alias /var/www/$host/.well-known;
    }
    location / {
        proxy_pass $proxy;
        proxy_set_header X-Real-IP \$remote_addr;
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
certbot certonly $staging --webroot -w $www -d $host
echo done

echo activating https website
ln -s $https $ehttps
service nginx reload
echo done
