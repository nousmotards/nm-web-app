FROM alpine:3.5

RUN apk update &&\
    apk add bash &&\
    rm -f /var/cache/apk/*
RUN mkdir -p /usr/share/nginx/html

ADD run.sh /
CMD ["/run.sh"]
