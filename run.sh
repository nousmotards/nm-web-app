#!/usr/bin/env bash

set -e

echo APP_NAME ${APP_NAME}
echo VERSION ${VERSION}
echo ENVIRONMENT ${ENVIRONMENT}
echo URL ${URL}
echo WGET_OPTIONS \"${WGET_OPTIONS}\"
echo WGET_USERNAME ${WGET_USERNAME}
echo WGET_PASSWORD $(test ! -z ${WGET_PASSWORD} && echo hidden)
echo AWS_ACCESS_KEY $(test ! -z ${AWS_ACCESS_KEY} && echo hidden)
echo AWS_SECRET_KEY $(test ! -z ${AWS_SECRET_KEY} && echo hidden)
echo AWS_REGION ${AWS_REGION}
echo AWS_BUCKET ${AWS_BUCKET}
echo ""

WGET_COMMON_OPTIONS='-q --timeout=5 -O /usr/share/nginx/html/app.tgz'
test ! -z ${WGET_USERNAME} && WGET_OPTIONS="${WGET_OPTIONS} --user=${WGET_USERNAME}"
test ! -z ${WGET_PASSWORD} && WGET_OPTIONS="${WGET_OPTIONS} --password=${WGET_PASSWORD}"
APP_COMMON_PATH="${APP_NAME}/${ENVIRONMENT}/${APP_NAME}_${VERSION}.tgz"
WGET_RCODE=0

# Default download method
echo "Downloading archive..."
wget ${WGET_COMMON_OPTIONS} ${WGET_OPTIONS} ${URL}/${APP_COMMON_PATH} || WGET_RCODE=$?

# Fallback download method
if [ $WGET_RCODE != 0 ] ; then
    echo "Using alternative solution to download app"
    contentType="text/html; charset=UTF-8"
    date="`date -u +'%a, %d %b %Y %H:%M:%S GMT'`"
    resource="/${AWS_BUCKET}/${APP_COMMON_PATH}"
    string="GET\n\n${contentType}\n\nx-amz-date:${date}\n${resource}"
    signature=`echo -en $string | openssl sha1 -hmac "${AWS_SECRET_KEY}" -binary | base64`
    WGET_RCODE=0
    wget ${WGET_COMMON_OPTIONS} \
         --header "x-amz-date: ${date}" \
         --header "Content-Type: ${contentType}" \
         --header "Authorization: AWS ${AWS_ACCESS_KEY}:${signature}" \
         "https://s3-${AWS_REGION}.amazonaws.com${resource}" || WGET_RCODE=$?

    if [ $WGET_RCODE != 0 ] ; then
        echo "Can't find the required app version in any location"
        exit 1
    fi
fi

echo "Decompress archive..."
tar --strip-components=1 -xzf /usr/share/nginx/html/app.tgz && rm -f /usr/share/nginx/html/app.tgz || exit 1
exit 0
