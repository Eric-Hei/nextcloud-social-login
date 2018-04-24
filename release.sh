#!/bin/bash

cd `dirname $0`
. .credentials

VERSION=v`grep '<version>' appinfo/info.xml | sed 's/[^0-9.]//g'`
UPLOAD_URL=`curl -sH "Authorization: token $GITHUB_TOKEN" -d "{\"tag_name\":\"$VERSION\"}" https://api.github.com/repos/zorn-v/nextcloud-social-login/releases | grep '"upload_url"' | sed 's/.*"\(https:.*\){.*/\1/'`
[ -z "$UPLOAD_URL" ] && echo Can not get assets url && exit 1

git checkout -b release
sed -i '/<description><\/description>/ {
  a <description><![CDATA[
  r README.md
  a ]]></description>
  d
}' appinfo/info.xml
git commit -am 'Release'
git archive release --prefix=sociallogin/ -o release.tar.gz
git checkout master
git branch -D release

curl -sH "Authorization: token $GITHUB_TOKEN" -H 'Content-Type: application/octet-stream' --data-binary '@release.tar.gz' ${UPLOAD_URL}?name=release.tar.gz > /dev/null
DOWNLOAD_URL=https://github.com/zorn-v/nextcloud-social-login/releases/download/$VERSION/release.tar.gz

SIG=`openssl dgst -sha512 -sign ~/.nextcloud/certificates/sociallogin.key release.tar.gz | openssl base64 -A`
curl -X POST -sH "Authorization: Token $NC_TOKEN" -H 'Content-Type: application/json' -d "{\"download\":\"$DOWNLOAD_URL\",\"signature\":\"$SIG\"}" https://apps.nextcloud.com/api/v1/apps/releases

rm -f release.tar.gz