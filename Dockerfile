FROM debian:jessie-slim

RUN apt-get update -y && \
    apt-get -qq -y --force-yes dist-upgrade --no-install-recommends && \
    apt-get -qq -y --force-yes install --no-install-recommends wget ca-certificates && \
    apt-get clean && \
    apt-get autoremove

RUN mkdir -p /usr/share/nginx/html

ADD run.sh /
CMD ["/run.sh"]
