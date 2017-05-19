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
server {" >$http
    listen 80;" >>$http
    listen [::]:80;" >>$http
    server_name $host;" >>$http
    location /.well-known {" >>$http
            alias /var/www/$host/.well-known;" >>$http
    }" >>$http
    location / {" >>$http
        return 301 https://$host;" >>$http
    }" >>$http
}" >>$http
echo done
EOF

echo creating $https
cat <<EOF > $https
server {" >$https
    listen 443 ssl;" >>$https
    listen [::]:443 ssl;" >>$https
    server_name $host;" >>$https
    ssl_certificate /etc/letsencrypt/live/$host/fullchain.pem;" >>$https
    ssl_certificate_key /etc/letsencrypt/live/$host/privkey.pem;" >>$https
    ssl_stapling on;" >>$https
    ssl_stapling_verify on;" >>$https
    ssl_dhparam $dhparam;" >>$https
    ssl_protocols TLSv1.2;" >>$https
    add_header Strict-Transport-Security max-age=31536000;" >>$https
    location /.well-known {" >>$https
            alias /var/www/$host/.well-known;" >>$https
    }" >>$https
    location / {" >>$https
        proxy_pass  $proxy;" >>$https
        proxy_set_header X-Real-IP  \$remote_addr;" >>$https
        proxy_set_header X-Forwarded-For \$remote_addr;" >>$https
        proxy_set_header Host \$host;" >>$https
        proxy_set_header X-Forwarded-Proto \$scheme;" >>$https
    }" >>$https
}" >>$https
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
