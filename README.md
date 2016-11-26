# nginx-proxy-generator

## Disclamer

This tools has been only tested on debian 8 and nginx 1.6.2. Other version have not been tested.

# Prerequies

- nginx >= 1.6
- OpenSSL
- [CertBot](https://certbot.eff.org/)

# Functionnality

1. Create www root folder
2. Create http configuration 
	1. .well-known folder for Let's Encrypt
	2. redirect to https
3. Create https configuration
	1. .well-known folder for Let's Encrypt
	1. Diffie-Hellman 4098 bytes
	2. Only [TLS 1.2](http://caniuse.com/#feat=tls1-2)
4. Activate http configuration
5. Request Let's Encrypt certificate
6. Activate https configuration
7. Enjoy !

Don't forget to renew regulary Let's Encrypt certificates. [https://certbot.eff.org/docs/using.html#renewing-certificates](https://certbot.eff.org/docs/using.html#renewing-certificates)

# Usage

	./generate [host] [proxy url]

Example

	./generate foo.bar.com http://bar.foo.com
