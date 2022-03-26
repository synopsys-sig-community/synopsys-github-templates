#!/bin/sh

registration_url="https://github.com/${GITHUB_OWNER}"
token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"

if [ -n "${GITHUB_TOKEN}" ]; then
    echo "Using given GITHUB_TOKEN"

    if [ -z "${GITHUB_REPOSITORY}" ]; then
        echo "When using GITHUB_TOKEN, the GITHUB_REPOSITORY must be set"
        return
    fi

    registration_url="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
    export RUNNER_TOKEN=$GITHUB_TOKEN

else
    if [ -n "${GITHUB_REPOSITORY}" ]; then
        token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
        registration_url="${registration_url}/${GITHUB_REPOSITORY}"
    fi

    echo "Requesting token at '${token_url}'"

    payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url})
    export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

fi

if [ -z "${RUNNER_NAME}" ]; then
    RUNNER_NAME=$(hostname)
fi

./config.sh \
    --name "${RUNNER_NAME}" \
    --token "${RUNNER_TOKEN}" \
    --url "${registration_url}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

# Initialize Polaris

POLARIS_DOWNLOAD=$POLARIS_URL/api/tools/polaris_cli-linux64.zip
curl -LsS -o polaris.zip $POLARIS_DOWNLOAD
unzip -j -d polaris-cli polaris.zip

mkdir temp-src && cd temp-src && ../polaris-cli/polaris --persist-config --co capture.build.buildCommands="null" --co capture.build.cleanCommands="null" --co capture.fileSystem="null" --co serverUrl=$POLARIS_URL configure && cd ..
export POLARIS_FF_ENABLE_COVERITY_INCREMENTAL=true
cd temp-src && echo Foo.java > changeset.txt && ../polaris-cli/polaris analyze -w --coverity-ignore-capture-failure --incremental ./changeset.txt  || cd .. || true

cleanup() {
    if [ -n "${GITHUB_TOKEN}" ]; then
        export REMOVE_TOKEN=$GITHUB_TOKEN
    else
        payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url%/registration-token}/remove-token)
        export REMOVE_TOKEN=$(echo $payload | jq .token --raw-output)
    fi

    ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh "$*" &

wait $!
