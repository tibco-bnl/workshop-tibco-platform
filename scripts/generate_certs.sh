cp workshop-tibco-platform/scripts/cert.config .
openssl genrsa -out self_sign_private_key.pem 2048
openssl req -new -config cert.config -key self_sign_private_key.pem -out certificate.csr
openssl x509 -req -in certificate.csr -signkey self_sign_private_key.pem -out self_signed_public.crt.pem -days 1095 -extensions ext -extfile cert.config
cat self_sign_private_key.pem | base64 | tr -d '\n'
cat self_signed_public.crt.pem | base64 | tr -d '\n'
export TLS_CERT=$(cat self_signed_public.crt.pem | tr -d '\n' | sed 's/-----BEGIN CERTIFICATE-----//g; s/-----END CERTIFICATE-----//g')
export TLS_KEY=$(cat self_sign_private_key.pem | tr -d '\n' | sed 's/-----BEGIN PRIVATE KEY-----//g; s/-----END PRIVATE KEY-----//g')
awk -v tls_cert="$TLS_CERT" '{gsub(/TLS_CERT=TO_BE_REPLACED/, "TLS_CERT=" tls_cert)} 1' ~/projects/platform-dev/workshop-tibco-platform/scripts/secrets.env > temp1.env
awk -v tls_cert="$TLS_KEY" '{gsub(/TLS_KEY=TO_BE_REPLACED/, "TLS_KEY=" tls_cert)} 1' temp1.env > temp2.env
mv -f temp2.env ~/projects/platform-dev/workshop-tibco-platform/scripts/secrets.env