FROM nginx:1.19.10-alpine

ENV NGX_PROXY_VERSION 0.0.2

# Download sources
# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk update && apk upgrade && \
    apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    patch \
    bash \
    git \
    openssh

RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  wget "https://github.com/chobits/ngx_http_proxy_connect_module/archive/v${NGX_PROXY_VERSION}.tar.gz" -O proxy.tar.gz


RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    mkdir -p /usr/src/nginx && mkdir -p /usr/src/proxy && \
    tar -zxC /usr/src/nginx -f nginx.tar.gz && \
    tar -zxC /usr/src/proxy -f proxy.tar.gz && \
    cd /usr/src/nginx/nginx-$NGINX_VERSION && \
    patch -p1 < /usr/src/proxy/ngx_http_proxy_connect_module-${NGX_PROXY_VERSION}/patch/proxy_connect_rewrite_1018.patch && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --add-dynamic-module=/usr/src/proxy/ngx_http_proxy_connect_module-${NGX_PROXY_VERSION} && \
    make && make install

RUN rm nginx.tar.gz && rm proxy.tar.gz && rm -rf /usr/src/nginx /usr/src/proxy

EXPOSE 80
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
