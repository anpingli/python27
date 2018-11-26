This repo contains clone of sclorg's [python27 repository](http://pkgs.devel.redhat.com/cgit/rpms/python27-docker/?h=rhscl-3.0-python27-rhel-7) along with definition of image standard test role and its usage.

To run the tests, install `ansible` package using your package manager and execute:

    $ cd tests
    $ ansible-playbook tests-openshift.yaml\
      -e image_name=<registry/[namespace]/name:tag>\
      -e short_image_name=<name:tag>\
      -e openshift_cluster_url=<openshift-cluster-to-run-the-tests-in>\
      -e openshift_username=<username-used-to-login>\
      -e openshift_auth_token=<authentication-token>\
      -e openshift_project_name=<project-name-the-tests-will-run-in>

Following changes were made to partially follow the Standard Test Interface naming/locations, but the testing system
and the tests themselves do _not_ completely follow the specification and users can not rely on that:

 * `test/` directory renamed to `tests/`
 * original content of the `test/` directory moved to `tests/scl-original` to archive the original state of tests
