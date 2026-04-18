# build health check bin
FROM golang:latest AS healthcheck-builder

WORKDIR /app
COPY healthcheck-go/go.mod healthcheck-go/go.sum* ./
COPY healthcheck-go/main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-s -w -extldflags "-static"' -o healthcheck main.go

# nginx build step
FROM ubuntu:26.04 AS build

# set environment variables
# latest stable nginx version
ARG NGINX_VERSION=1.30.0
ARG TZ=Europe/Berlin
ARG NGINX_PORT=8080
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools, libraries and utilities 
RUN apt-get update  \
    && apt-get install -y --no-install-recommends --no-install-suggests build-essential ca-certificates curl libpcre3 libpcre3-dev wget zlib1g-dev unzip make gcc g++ libarchive-tools gnupg tzdata autoconf jq \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# retrieve, verify , unpack and build nginx from source
COPY --chmod=755 install.sh /root/install.sh
# run install script
RUN sh /root/install.sh
# delete install script
RUN rm /root/install.sh

# create required nginx directories
RUN mkdir -p /usr/local/nginx/client_body_temp \
    /usr/local/nginx/proxy_temp \
    /usr/local/nginx/fastcgi_temp \
    /usr/local/nginx/uwsgi_temp \
    /usr/local/nginx/scgi_temp

# symlink access and error logs to /dev/stdout and /dev/stderr
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/nginx/logs/error.log

# add a non-root user 'nginx' and set ownership
RUN groupadd -r nginx && useradd -r -g nginx -d /usr/local/nginx -s /sbin/nologin nginx \
    && chown -R nginx:nginx /usr/local/nginx

# copy nginx configuration file and adjust to custom port (when is set)
COPY --chown=nginx:nginx nginx.conf /usr/local/nginx/conf/nginx.conf
RUN sed -i "s/listen\s*8080 default_server;/listen       ${NGINX_PORT} default_server;/g" /usr/local/nginx/conf/nginx.conf

# final stage
FROM scratch

# set environment variables
ARG NGINX_PORT=8080
ENV NGINX_PORT=${NGINX_PORT}

# customise static content, and configuration
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/localtime /etc/localtime
COPY --from=build /etc/ssl /etc/ssl
COPY --from=build /etc/os-release /etc/os-release
COPY --from=build /usr/share/zoneinfo/ /usr/share/zoneinfo/
COPY --from=build --chown=nginx:nginx /usr/local/nginx /usr/local/nginx
COPY --chown=nginx:nginx html/index.html /usr/local/nginx/html/index.html
COPY --from=build --chown=nginx:nginx /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf
COPY --from=healthcheck-builder /app/healthcheck /usr/local/bin/healthcheck

# use non-privileged user
USER nginx

# define healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 CMD ["/usr/local/bin/healthcheck"]

# change default stop signal from SIGTERM to SIGQUIT
STOPSIGNAL SIGQUIT

# define entrypoint and default parameters 
ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;","-c", "/usr/local/nginx/conf/nginx.conf"]