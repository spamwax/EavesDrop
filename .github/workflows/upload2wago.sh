#!/usr/bin/env bash
set -x

cat <<END > metadata.json
{
  "label": "$TAG_NAME",
  "stability": "stable",
  "changelog": "Release v$TAG_NAME
  $CHANGELOG",
  "supported_retail_patch": "9.2.7"
}
END

metadata=$(<metadata.json)
echo
echo "$metadata"
echo
ls -l
echo

curl -f -X POST -F "metadata=<metadata.json"\
  -F "file=@EavesDrop.zip"\
  -H "authorization: Bearer $WAGO_API_TOKEN"\
  -H "accept: application/json"\
  https://addons.wago.io/api/projects/"$WAGO_PROJECT_ID"/version && rm -rf metadata.json
