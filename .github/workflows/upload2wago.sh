#!/usr/bin/env bash

read -r -d '' metadata <<'END'
{
  "lable": "$TAG_NAME",
  "stability": "stable",
  "changelog": "### Release v$TAG_NAME"
  "supported_retail_patch": "9.2.7",
  "supported_retail_patch": "3.4.0"
}
END

echo $metadata
echo
ls -l
echo

# curl -f -X POST -F "metadata=$metadata" -F "file=@EavesDrop.zip" -H "authorization: Bearer $WAGO_API_KEY" -H "accept: application/json" https://addons.wago.io/api/projects/"$WAGO_PROJECT_ID"/version
echo "curl -f -X POST -F metadata=$metadata -F file=@EavesDrop.zip -H authorization: Bearer $WAGO_API_KEY -H accept: application/json https://addons.wago.io/api/projects/$WAGO_PROJECT_ID/version"
