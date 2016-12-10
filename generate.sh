#!/bin/bash

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

echo www folder : $www
echo http sites-available : $http
echo http sites-enabled : $ehttp
echo https sites-available : $https
echo https sites-enabled : $ehttp
echo dhparam : $dhparam

echo "Warning, this script will reload multiple times nginx, use Ctrl-C now to cancel script"
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
echo "server {" >$http
echo "    listen 80;" >>$http
echo "    listen [::]:80;" >>$http
echo "    server_name $host;" >>$http
echo "    location /.well-known {" >>$http
echo "            alias /var/www/$host/.well-known;" >>$http
echo "    }" >>$http
echo "    location / {" >>$http
echo "        return 301 https://$host;" >>$http
echo "    }" >>$http
echo "}" >>$http
echo done

echo creating $https
echo "server {" >$https
echo "    listen 443 ssl;" >>$https
echo "    listen [::]:443 ssl;" >>$https
echo "    server_name $host;" >>$https
echo "    ssl_certificate /etc/letsencrypt/live/$host/fullchain.pem;" >>$https
echo "    ssl_certificate_key /etc/letsencrypt/live/$host/privkey.pem;" >>$https
echo "    ssl_stapling on;" >>$https
echo "    ssl_stapling_verify on;" >>$https
echo "    ssl_dhparam $dhparam;" >>$https
echo "    ssl_protocols TLSv1.2;" >>$https
echo "    add_header Strict-Transport-Security max-age=31536000;" >>$https
echo "    location /.well-known {" >>$https
echo "            alias /var/www/$host/.well-known;" >>$https
echo "    }" >>$https
echo "    location / {" >>$https
echo "        proxy_pass  $proxy;" >>$https
echo "        proxy_set_header X-Real-IP  \$remote_addr;" >>$https
echo "        proxy_set_header X-Forwarded-For \$remote_addr;" >>$https
echo "        proxy_set_header Host \$host;" >>$https
echo "    }" >>$https
echo "}" >>$https
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
