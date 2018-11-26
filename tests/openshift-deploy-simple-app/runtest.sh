#!/usr/bin/env bash

set -e

THISDIR=$(dirname ${BASH_SOURCE[0]})

oc login ${OPENSHIFT_CLUSTER_URL} --token="${OPENSHIFT_AUTH_TOKEN}" --insecure-skip-tls-verify
oc project ${OPENSHIFT_PROJECT_NAME}
# log the initial state of the project; useful for debugging
oc get all

oc import-image ${IMAGE_NAME} --from=${IMAGE_FULL_NAME} --insecure=true --confirm

importedImageUrl=$(oc get is ${IMAGE_NAME} --template='{{ .status.dockerImageRepository }}')
oc process -f "${THISDIR}/simple-test-app-template.yaml"\
 -p NAMESPACE="${OPENSHIFT_PROJECT_NAME}"\
 -p PYTHON_BUILDER_IMAGE="$importedImageUrl"\
 | oc apply --force=true -f -

# the sources need to be copied outside of the git repository, otherwise the OpenShift client (oc) is trying to be smart
# and uses the whole git repository as input to the build (instead of just the specified sub-dir)
cp -r "${THISDIR}/simple-test-app" /tmp
buildResourceName=$(oc start-build simple-python-test-app --from-dir=/tmp/simple-test-app -o name) # --follow is buggy
# wait for the build to finish
echo "Waiting for ${buildResourceName} fo finish..."
oc logs -f "${buildResourceName}"

service_url=$(oc get route simple-python-test-app --template='{{ .spec.host }}')
# make sure the service is properly created and bound to the route
for i in {1..60}; do
  if wget --no-check-certificate -O ${THISDIR}/index.html "${service_url}"; then
     echo "Service responding at ${service_url}"
     # check the content of the downloaded file
     if grep -q "Hello World from standalone WSGI application!" "${THISDIR}/index.html" ; then
       echo "Service responded with the expected content."
       exit 0
     else
       echo "Got unexpected content from the service!"
       echo "Expected: Hello World from standalone WSGI application!"
       echo "  Actual: `cat "${THISDIR}/index.html"`"
       exit 2
     fi
  fi
  sleep 1
done

# service wasn't reachable, fail the test
echo "Service is not reachable at: ${service_url}"
exit 1
