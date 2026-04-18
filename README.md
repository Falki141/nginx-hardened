# nginx-hardened

This image provides a rootless Nginx container for static content. Based on "From-Scratch", we build the nginx binary and copy to it.
For better security we add a nginx user without root rights.

## How to use

Dockerfile:

```bash
FROM falki141/nginx-hardened-:latest
# your own nginx configuration
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
# your static content
COPY html/ /usr/share/nginx/html
```

Use theese commands to build the image and run the container:
```bash
# build the image
docker build -t your-custom-nginx .
# build with custom timezone
docker build --build-arg TZ=Europe/Berlin -t your-custom-nginx .
# build with custom port
docker build --build-arg NGINX_PORT=9999 -t your-custom-nginx .
# run the container custom port 9999
docker run --rm -d -p 8080:9999 --name nginx-hardened your-custom-nginx
# run the container default port 8080
docker run --rm -d -p 8080:8080 --name nginx-hardened your-custom-nginx
# test it
curl -L http://localhost:8080


```