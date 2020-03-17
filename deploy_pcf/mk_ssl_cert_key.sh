#!/bin/bash
set -e

[[ ${1} ]] && DOMAIN=${1}
: ${DOMAIN:?must be set the DNS domain root (ex: example.cf-app.com)}
: ${KEY_BITS:=2048}
: ${DAYS:=1}

openssl req -new -x509 -nodes -sha256 -newkey rsa:${KEY_BITS} -days ${DAYS} -keyout ${DOMAIN}.ca.key.pkcs8 -out ${DOMAIN}.ca.crt -config <( cat << EOF
[ req ]
prompt = no
distinguished_name    = dn

[ dn ]
C  = US
O = Pivotal
CN = Toolsmiths autogenerated CA

EOF
)

openssl rsa -in ${DOMAIN}.ca.key.pkcs8 -out ${DOMAIN}.ca.key

openssl req -nodes -sha256 -newkey rsa:${KEY_BITS} -days ${DAYS} -keyout ${DOMAIN}.key -out ${DOMAIN}.csr -config <( cat << EOF
[ req ]
prompt = no
distinguished_name    = dn
req_extensions = v3_req

[ dn ]
C  = US
O = Pivotal
CN = *.${DOMAIN}

[ v3_req ]
subjectAltName = DNS:*.${DOMAIN}, DNS:*.apps.${DOMAIN}, DNS:*.sys.${DOMAIN}, DNS:*.login.sys.${DOMAIN}, DNS:*.uaa.sys.${DOMAIN}
EOF
)

openssl x509 -req -in ${DOMAIN}.csr -CA ${DOMAIN}.ca.crt -CAkey ${DOMAIN}.ca.key.pkcs8 -CAcreateserial -out ${DOMAIN}.host.crt -days ${DAYS} -sha256 -extfile <( cat << EOF
basicConstraints = CA:FALSE
subjectAltName = DNS:*.${DOMAIN}, DNS:*.apps.${DOMAIN}, DNS:*.sys.${DOMAIN}, DNS:*.login.sys.${DOMAIN}, DNS:*.uaa.sys.${DOMAIN}
subjectKeyIdentifier = hash
EOF
)

cat ${DOMAIN}.host.crt ${DOMAIN}.ca.crt > ${DOMAIN}.crt
