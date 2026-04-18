set -x
set -euo

NGINX_TAR="nginx-${NGINX_VERSION}.tar.gz"
NGINX_URL="https://nginx.org/download/${NGINX_TAR}"
PGP_KEY_1_URL="https://nginx.org/keys/pluknet.key"
PGP_KEY_2_URL="https://nginx.org/keys/arut.key"
PGP_KEY_3_URL="https://nginx.org/keys/sb.key"
PGP_KEY_4_URL="https://nginx.org/keys/thresh.key"

PGP_KEY_1="pluknet.key"
PGP_KEY_2="arut.key"
PGP_KEY_3="sb.key"
PGP_KEY_4="thresh.key"

PGP_SIG="${NGINX_TAR}.asc"
# download the PGP key
curl -O ${PGP_KEY_1_URL}
curl -O ${PGP_KEY_2_URL}
curl -O ${PGP_KEY_3_URL}
curl -O ${PGP_KEY_4_URL}

# download the nginx source tarball and its signature
curl -O ${NGINX_URL}
curl -O "${NGINX_URL}.asc"
# import the PGP key
gpg --import ${PGP_KEY_1}
gpg --import ${PGP_KEY_2}
gpg --import ${PGP_KEY_3}
gpg --import ${PGP_KEY_4}

# verify the PGP signature
gpg --verify ${PGP_SIG} ${NGINX_TAR}
tar -xf nginx-${NGINX_VERSION}.tar.gz
# build and install nginx
cd nginx-$NGINX_VERSION && ls -la && ./configure --with-ld-opt="-static" --with-http_sub_module --error-log-path="/dev/stdout" --http-log-path="/dev/stdout"
make install
strip /usr/local/nginx/sbin/nginx