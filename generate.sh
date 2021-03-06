#!/bin/bash
: '
nginx-proxy-generator
Copyright (C) 2021 fa18swiss

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

'

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
proxyconf=/etc/nginx/proxy_params
sslconf=/etc/nginx/ssl_params


cat <<EOF
www folder : $www
http sites-available : $http
http sites-enabled : $ehttp
https sites-available : $https
https sites-enabled : $ehttp
dhparam : $dhparam
proxyconf : $proxyconf
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

echo creating or updating proxy configuration
cat <<EOF > $proxyconf
proxy_set_header Host \$http_host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_set_header X-Forwarded-Host \$host;

proxy_read_timeout 300;
proxy_connect_timeout 300;
proxy_send_timeout 300;
EOF

echo creating or updating ssl configuration
cat <<EOF > $sslconf
ssl_session_tickets off;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_dhparam $dhparam;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_stapling on;
ssl_stapling_verify on;

add_header Strict-Transport-Security max-age=31536000; 
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
    ssl_trusted_certificate /etc/letsencrypt/live/$host/chain.pem;
    include $sslconf;    
    location /.well-known {
            alias /var/www/$host/.well-known;
    }
    location / {
        proxy_pass $proxy;
        include $proxyconf;
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
