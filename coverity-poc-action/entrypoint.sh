#!/bin/bash -x

INPUTS_DEBUG=${1}
echo INPUTS_DEBUG: $INPUTS_DEBUG
INPUTS_COVERITY_URL=${2}
echo INPUTS_COVERITY_URL: $INPUTS_COVERITY_URL
INPUTS_COVERITY_USER=${3}
echo INPUTS_COVERITY_USER: $INPUTS_COVERITY_USER
INPUTS_COVERITY_PASSPHRASE=${4}
echo INPUTS_COVERITY_PASSPHRASE: $INPUTS_COVERITY_PASSPHRASE
INPUTS_BUILD_COMMAND=${5}
echo INPUTS_BUILD_COMMAND: $INPUTS_BUILD_COMMAND
INPUTS_COV_BUILD_OPTIONS=${6}
echo INPUTS_COV_BUILD_OPTIONS: $INPUTS_COV_BUILD_OPTIONS
INPUTS_COV_ANALYZE_OPTIONS=${7}
echo INPUTS_COV_ANALYZE_OPTIONS: $INPUTS_COV_ANALYZE_OPTIONS
INPUTS_SECURITY_GATE_VIEW_NAME=${8}
echo INPUTS_SECURITY_GATE_VIEW_NAME: $INPUTS_SECURITY_GATE_VIEW_NAME
INPUTS_COVERITY_CHECKER_OPTIONS=${9}
echo INPUTS_COVERITY_CHECKER_OPTIONS: $INPUTS_COVERITY_CHECKER_OPTIONS
INPUTS_COVERITY_STREAM_NAME=${10}
echo INPUTS_COVERITY_STREAM_NAME: $INPUTS_COVERITY_STREAM_NAME
INPUTS_COVERITY_PROJECT_NAME=${11}
echo INPUTS_COVERITY_PROJECT_NAME: $INPUTS_COVERITY_PROJECT_NAME
INPUTS_GENERATE_SARIF=${12}
echo INPUTS_GENERATE_SARIF: $INPUTS_GENERATE_SARIF
INPUTS_GITHUB_TOKEN=${13}
echo INPUTS_GITHUB_TOKEN: $INPUTS_GITHUB_TOKEN
INPUTS_DIAGNOSTIC_MODE=${14}
echo INPUTS_DIAGNOSTIC_MODE: $INPUTS_DIAGNOSTIC_MODE
INPUTS_CREATE_STREAM_AND_PROJECT=${15}
echo INPUTS_CREATE_STREAM_AND_PROJECT: $INPUTS_CREATE_STREAM_AND_PROJECT
INPUTS_COVERITY_LICENSE=${16}
echo INPUTS_COVERITY_LICENSE: $INPUTS_COVERITY_LICENSE

export COV_USER=$INPUTS_COVERITY_USER
export COVERITY_PASSPHRASE=$INPUTS_COVERITY_PASSPHRASE

export PATH=/home/coverity/cov-analysis-linux64/bin:$PATH

echo ========================================================================================
echo == Coverity License
echo ========================================================================================

# TODO: Debug Coverity License secret issue, in the meantime this is un-reachable without the password
COVERITY_LICENSE="https://thirteen.community/private/license.dat"
curl -u "$COV_USER":"$COVERITY_PASSPHRASE" "$COVERITY_LICENSE" > coverity-license.dat
ls -l coverity-license.dat

if [[ "$GITHUB_EVENT_NAME" != "pull_request" ]]; then
  if [[ "$INPUTS_CREATE_STREAM_AND_PROJECT" == "true" ]]; then
    echo
    echo ========================================================================================
    echo == Initialize Coverity project and stream
    echo ========================================================================================
    echo
    if [[ "$INPUTS_COVERITY_STREAM_NAME" == "" ]]; then
      export COVERITY_STREAM_NAME=${GITHUB_REPOSITORY##*/}-${GITHUB_REF##*/}
    else
      export COVERITY_STREAM_NAME=$INPUTS_COVERITY_STREAM_NAME
    fi
    if [[ "$INPUTS_COVERITY_PROJECT_NAME" == "" ]]; then
      export COVERITY_PROJECT_NAME=${GITHUB_REPOSITORY##*/}
    else
      export COVERITY_PROJECT_NAME=$INPUTS_COVERITY_PROJECT_NAME
    fi
    echo Ensure that project "$COVERITY_PROJECT_NAME" exists
    cov-manage-im --url $INPUTS_COVERITY_URL --on-new-cert trust --mode projects --add --set name:"$COVERITY_PROJECT_NAME" || true
    echo Ensure that stream "$COVERITY_STREAM_NAME" exists
    cov-manage-im --url $INPUTS_COVERITY_URL --on-new-cert trust --mode streams --add -set name:"$COVERITY_STREAM_NAME" || true
    cov-manage-im --url $INPUTS_COVERITY_URL --on-new-cert trust --mode projects --update --name "$COVERITY_PROJECT_NAME" --insert stream:"$COVERITY_STREAM_NAME" || true
  fi
fi

# Always run either a full build or auto-capture. A partial capture is possible for incremental analysis,
# but this will impact the results further. For C/C++ and large Java projects however this may be required
# and is left as an exercise to the reader.
if [[ "$INPUTS_BUILD_COMMAND" == "" ]]; then
  echo
  echo ========================================================================================
  echo == Run Coverity AUTO Capture
  echo ========================================================================================
  echo
  cov-capture --dir idir --project-dir .
else
  echo
  echo ========================================================================================
  echo == Run Coverity BUILD Capture: $INPUTS_BUILD_COMMAND
  echo ========================================================================================
  echo
  cov-build --dir idir $INPUTS_COV_BUILD_OPTIONS $INPUTS_BUILD_COMMAND
fi

# On pushes to a main branch, run a Full Coverity analysis using auto
# capture. This will scan the filesystem to determine what kind of
# project(s) are present and how to capture them for analysis.
#
# The results will be committed to the stream specified in the
# previous step.
#
# Results will be saved into coverity-full-results.json for
# potential processing.

if [[ "$GITHUB_EVENT_NAME" != "pull_request" ]]; then
  echo
  echo ========================================================================================
  echo == Run FULL Coverity analysis for ${GITHUB_REPOSITORY##*/}-${GITHUB_REF##*/}
  echo ========================================================================================
  echo
  if [[ "$INPUTS_COVERITY_STREAM_NAME" == "" ]]; then
    export COVERITY_STREAM_NAME=${GITHUB_REPOSITORY##*/}-${GITHUB_REF##*/}
  else
    export COVERITY_STREAM_NAME=$INPUTS_COVERITY_STREAM_NAME
  fi
  cov-analyze --dir idir --strip-path `pwd` --security-file coverity-license.dat $INPUTS_COVERITY_CHECKER_OPTIONS $INPUTS_COV_ANALYZE_OPTIONS
  cov-commit-defects --dir idir --ticker-mode none --url $INPUTS_COVERITY_URL --on-new-cert trust --stream \
    $COVERITY_STREAM_NAME --scm git --description "GitHub Workflow $GITHUB_WORKFLOW for $GITHUB_REPO" --version $GITHUB_SHA \
    --security-file coverity-license.dat
  cov-format-errors --dir idir --security-file coverity-license.dat --json-output-v7 coverity-results.json
fi

# On a pull request, run an incremental analysis. This uses auto
# capture as well, and references a stream that was presumably
# created in advance by a push to this repo, using the stream name
# based on the repository and main branch name (e.g. "master").
#
# This implementation uses a full capture rather than a partial
# capure, as the partial capture will cause increased variability
# in the Coverity results compared to full analysis.
#
# If maximum speed is desired in favor of complete resulsts, you may
# add:
#     --source-list coverity-files-to-scan.txt
# to the cov-capture invokation.
#
# Results are saved into coverity-results.json.

if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
  export BASE_BRANCH=$GITHUB_BASE_REF

  echo
  echo ========================================================================================
  echo == Run INCREMENTAL Coverity analysis for ${GITHUB_REPOSITORY##*/}-$BASE_BRANCH
  echo ========================================================================================
  echo
  if [[ "$INPUTS_COVERITY_STREAM_NAME" == "" ]]; then
    export COVERITY_STREAM_NAME=${GITHUB_REPOSITORY##*/}-$BASE_BRANCH
  else
    export COVERITY_STREAM_NAME=$INPUTS_COVERITY_STREAM_NAME
  fi

  # JC: Use the wrapper's call to coverity-files-to-scan.txt instead
  #git --no-pager diff origin/$GITHUB_BASE_REF --name-only > coverity-files-to-scan.txt
  echo Scanning changed files:
  cat coverity-files-to-scan.txt

  cov-run-desktop --dir idir --strip-path `pwd` --url $INPUTS_COVERITY_URL \
    --stream $COVERITY_STREAM_NAME --present-in-reference false \
    --ignore-uncapturable-inputs true \
    --json-output-v7 coverity-results.json \
    --security-file coverity-license.dat \
    $INPUTS_COV_ANALYZE_OPTIONS \
    @@coverity-files-to-scan.txt

  cov-commit-defects --dir idir --url $INPUTS_COVERITY_URL --preview-report-v2 preview-report.json \
    --stream ${COVERITY_STREAM_NAME} \
    --security-file coverity-license.dat
  NUM_NEW_DEFECTS=`cat preview-report.json | jq -re .issueInfo[].presentInComparisonSnapshot | grep false | wc -l || true`
  echo $NUM_NEW_DEFECTS > coverity-desktop-defects-count.txt
fi

if [[ "$INPUTS_GENERATE_SARIF" == "true" ]]; then
  echo
  echo ========================================================================================
  echo == Generate SARIF for Coverity results
  echo ========================================================================================
  echo
  COV_ANALYZE_PATH=`which cov-analyze`
  COVERITY_HOME=`dirname $COV_ANALYZE_PATH`
  node $COVERITY_HOME/../SARIF/cov-format-sarif-for-github.js \
    --inputFile coverity-results.json \
    --repoName $GITHUB_REPOSITORY \
    --checkoutPath $GITHUB_REPOSITORY `pwd` $GITHUB_SHA \
    --outputFile synopsys-coverity-github-sarif.json
fi
