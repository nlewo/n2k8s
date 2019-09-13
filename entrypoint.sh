#!/usr/bin/env bash
set -euo pipefail

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --context)
            CONTEXT="$2"
            ;;
        --destination)
            DESTINATION="$2"
            ;;
        --aws-region)
            AWS_REGION="$2"
            ;;
        --image-manifest-filepath)
            IMAGE_MANIFEST_FILEPATH="$2"
            ;;
        *)    # unknown option
        echo "Unknown argument $1"
        exit 1
        ;;
    esac
    shift # past argument
    shift # past value
done

SKOPEO_CMD=(skopeo copy)
if [[ -n ${AWS_REGION+x} ]];
then
    echo "* geting AWS credentials..."
    PWD=$(aws ecr get-login --no-include-email --region eu-west-1 | cut -d" " -f6)    
    SKOPEO_CMD+=(--dest-creds AWS:"${PWD}")
fi

echo "* move to ${CONTEXT}...."
cd "${CONTEXT}"

echo "* build started...."
nix-build
HASH=$(realpath ./result | xargs basename | cut -d- -f1)

echo "* push to registry...."
"${SKOPEO_CMD[@]}" --dest-tls-verify=false docker-archive://"${PWD}"/result docker://"${DESTINATION}":"${HASH}"

if [[ -n ${IMAGE_MANIFEST_FILEPATH+x} ]];
then
    echo "* exposing the image manifest"
    mkdir -p $(dirname ${IMAGE_MANIFEST_FILEPATH})
    skopeo inspect docker-archive://"${PWD}"/result > ${IMAGE_MANIFEST_FILEPATH}
fi
