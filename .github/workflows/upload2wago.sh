#!/usr/bin/env bash
set -x

# read -r -d '' metadata <<'END'
cat <<END > metadata.json
{
  "lable": "$TAG_NAME",
  "stability": "stable",
  "changelog": "Release v$TAG_NAME",
  "supported_retail_patch": "9.2.7"
}
END

# read -r metadata <<< metadata.json
metadata=$(<metadata.json)
echo
echo $metadata
echo
ls -l
echo
# curl -f -X POST -F "metadata=$metadata" -F "file=@EavesDrop.zip" -H "authorization: Bearer $WAGO_API_KEY" -H "accept: application/json" https://addons.wago.io/api/projects/"$WAGO_PROJECT_ID"/version
# echo -F \"metadata=$metadata\" -F \"file=@EavesDrop.zip\"


# curl -f -X POST -F \"metadata=$metadata\" -F \"file=@EavesDrop.zip\" -H \"authorization: Bearer $WAGO_API_TOKEN\" -H \"accept: application/json\" https://addons.wago.io/api/projects/"$WAGO_PROJECT_ID"/version
curl -f -X POST -F "metadata=<metadata.json" -F "file=@EavesDrop.zip" -H "authorization: Bearer $WAGO_API_TOKEN" -H "accept: application/json" https://addons.wago.io/api/projects/"$WAGO_PROJECT_ID"/version


# echo curl -f -X POST -F \"metadata='{' \"lable\": \"$TAG_NAME\", \"stability\": \"stable\",\
#     \"changelog\": \"### Release v$TAG_NAME\",\
#     \"supported_retail_patch\": \"9.2.7\", \"supported_retail_patch\": \"3.4.0\" '}'\"\
#     -F \"file=@EavesDrop.zip\"\
#     -H \"authorization: Bearer $WAGO_API_KEY\"\
#     -H \"accept: application/json\" https://addons.wago.io/api/projects/$WAGO_PROJECT_ID/version
