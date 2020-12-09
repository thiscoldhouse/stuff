#!/bin/bash

# Generates SSL cert for internal use in either production or
# staging.
# Usage example:
# ./generate_ssl_cert.sh <ip_or_hostname_or_whatever>

dotkeyfilename=
dotpemfilename=
if [ ! -f $dotkeyfilename ]; then
    echo "This file must be run in the same directory as $dotkeyfilename"
    exit 1
fi

if [ ! -f $dotpemfilename ]; then
    echo "This file must be run in the same directory as $dotpemfilename"
    exit 1
fi

if [ -z "$1" ]
then
    echo "Missing argument, see usage example at top of file"
    exit 1
fi

openssl genrsa -out $1.key 2048
openssl req -new -key $1.key -out $1.csr


cat > temp.ext <<- EOM
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $1
EOM

openssl x509 -req -in $1.csr -CA $dotpemfilename -CAkey $dotkeyfilename -CAcreateserial -out $1.crt -sha256 -extfile temp.ext

rm temp.ext
