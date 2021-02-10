# nginx-proxy-generator

## Disclamer

This tools has been only tested on :

- Ubuntu 20.04 with nginx 1.18.0

Other version have not been tested.

On first run, this tool create a DH key of 4096 bits for [perfect forward secrecy](https://en.wikipedia.org/wiki/Forward_secrecy), that can take a (very) long time. Can it be generated with all CPU : [check here](https://mta.openssl.org/pipermail/openssl-users/2017-March/005457.html)

# Prerequies

- [nginx](https://nginx.org) >= 1.13.0
- [OpenSSL](https://www.openssl.org)  >= 1.1.1
- [CertBot](https://certbot.eff.org)

# Functionnality

1. Create www root folder
2. Create http configuration 
	1. .well-known folder for Let's Encrypt
	2. redirect to https
3. Create https configuration
	1. .well-known folder for Let's Encrypt
	2. Diffie-Hellman 4098 bytes
	3. Only [TLS 1.2](https://caniuse.com/tls1-2) and [TLS 1.3](https://caniuse.com/tls1-3)
	4. Only strong cipher suites
	5. Long time [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security) header
4. Activate http configuration
5. Request Let's Encrypt certificate
6. Activate https configuration
7. Enjoy !

Don't forget to renew regulary Let's Encrypt certificates. [https://certbot.eff.org/docs/using.html#renewing-certificates](https://certbot.eff.org/docs/using.html#renewing-certificates)

# Usage

	./generate.sh [host] [proxy url] [-s (use the staging version to test network)]

Example

	./generate.sh foo.bar.com http://bar.foo.com:81

# References :

[moz://a SSL Configuration Generator](https://ssl-config.mozilla.org)
