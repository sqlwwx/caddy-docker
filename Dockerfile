#
# Builder
#
FROM sqlwwx/golang-builder as builder

# builder dependency
RUN git clone --depth=1 https://github.com/caddyserver/builds /go/src/github.com/caddyserver/builds

# plugin helper
RUN go get -v github.com/abiosoft/caddyplug/caddyplug

# plugins
RUN for plugin in $(echo $plugins | tr "," " "); do \
    go get -v $(caddyplug package $plugin); \
    printf "package caddyhttp\nimport _ \"$(caddyplug package $plugin)\"" > \
        /go/src/github.com/mholt/caddy/caddyhttp/$plugin.go ; \
    done

RUN git clone https://github.com/mholt/caddy /go/src/github.com/mholt/caddy

ARG version="0.11.2"
ARG plugins="git"

RUN cd /go/src/github.com/mholt/caddy; git pull
# caddy
RUN cd /go/src/github.com/mholt/caddy \
    && git checkout -b "v${version}"

RUN cd /go/src/github.com/caddyserver/builds; git pull

# build
RUN cd /go/src/github.com/mholt/caddy/caddy \
    && git checkout -f \
    && go run build.go \
    && mv caddy /go/bin \
    && cd /go/bin \
    && upx -9 caddy

#
# Final stage
#
FROM alpine:3.8
LABEL maintainer "sqlwwx <wwx_2012@live.com>"
LABEL caddy_version="0.11.2"

RUN echo http://mirrors.aliyun.com/alpine/v3.8/main > /etc/apk/repositories; \
    echo http://mirrors.aliyun.com/alpine/v3.8/community >> /etc/apk/repositories

RUN apk update \
    apk upgrade

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /go/bin/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout"]
