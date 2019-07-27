# nginx-proxy-generator

## Disclamer

This tools has been only tested on :

- Ubuntu 16.04 with nginx 1.10.3

Other version have not been tested.

On first run, this tool create a DH key of 4096 bits for [perfect forward secrecy](https://en.wikipedia.org/wiki/Forward_secrecy), that can take a long time.

# Prerequies

- nginx >= 1.10
- OpenSSL  >= 1.0.2
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

	./generate.sh [host] [proxy url] [-s (use the staging version to test network)]

Example

	./generate.sh foo.bar.com http://bar.foo.com:81

# References :

[moz://a SSL Configuration Generator](https://ssl-config.mozilla.org)
