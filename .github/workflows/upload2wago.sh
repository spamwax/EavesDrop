#!/usr/bin/env bash
# DO NOT MOVE THE NEXT 3 LINES. Their value should always be equivalent to 'Interface' in .toc files
# A pre-commit git script will use these and compare to .toc files.
SUPPORTED_RETAIL_PATCH=11.0.0
SUPPORTED_CATA_PATCH=4.4.0

set -x

cat <<END > metadata.json
{ "label": "$TAG_NAME", "stability": "stable", "changelog": "Release v$TAG_NAME\\n\\n$CHANGELOG", "supported_retail_patch": "$SUPPORTED_RETAIL_PATCH", "supported_cata_patch": "$SUPPORTED_CATA_PATCH" }
END

sed -z -i 's/\n$//;s/\n/\\n/g' metadata.json
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
