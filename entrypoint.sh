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

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker/config.json}
REGISTRY=$(echo "$DESTINATION" | cut -d"/" -f1)
SKOPEO_COPY_CMD=(skopeo copy)
SKOPEO_INSPECT_CMD=(skopeo inspect)

if jq -e "(. | has(\"credHelpers\")) and (.credHelpers.\"$REGISTRY\" | . == \"ecr-login\")" < "$DOCKER_CONFIG" > /dev/null
then
    # Since we need to know the AWS region to get the login, we infer
    # it from the registry url.
    AWS_REGISTRY_URL=$(jq -e '.credHelpers < "$DOCKER_CONFIG" | keys | .[0]' -r)
    AWS_REGION=$(echo "$AWS_REGISTRY_URL" | awk -F "." '{print $(NF-2)}')
    echo "* get credentials for the AWS registry on AWS region" "$AWS_REGION"
    PWD=$(aws ecr get-login --no-include-email --region "$AWS_REGION" | cut -d" " -f6)
    SKOPEO_COPY_CMD+=(--dest-creds AWS:"${PWD}")
    SKOPEO_INSPECT_CMD+=(--creds AWS:"${PWD}")
fi

echo "* cd to ${CONTEXT}...."
cd "${CONTEXT}"

echo "* check if the image has been already pushed "
HASH=$(nix-instantiate | xargs nix-store -q | cut -d"/" -f 4 | cut -d"-" -f 1)
if "${SKOPEO_INSPECT_CMD[@]}" --tls-verify=false docker://"${DESTINATION}":"${HASH}" > /dev/null
then
    echo "* skip the build since the image has been already pushed...."
else
    echo "* build started...."
    # TODO: do not create ./result
    nix-build
    HASH=$(realpath ./result | xargs basename | cut -d- -f1)

    echo "* push to registry: ${DESTINATION}:${HASH}"
    "${SKOPEO_COPY_CMD[@]}" --dest-tls-verify=false docker-archive://"${PWD}"/result docker://"${DESTINATION}":"${HASH}"
fi

if [[ -n ${IMAGE_MANIFEST_FILEPATH+x} ]];
then
    echo "* exposing the image manifest"
    mkdir -p "$(dirname "${IMAGE_MANIFEST_FILEPATH}")"
    skopeo inspect docker://"${DESTINATION}":"${HASH}" > "${IMAGE_MANIFEST_FILEPATH}"
fi
