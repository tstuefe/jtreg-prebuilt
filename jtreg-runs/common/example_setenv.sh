
export OPENJDK_ROOT=/shared/projects/openjdk

export CODELINE_DEFAULT="jdk-jdk"

# The JTREG version to use. Refers to prebuilt dir.
# Valid values are "jtreg" (just a symlink to the latest version) or specific versions like "jtreg-7.5.2"
export JTREG_VERSION="jtreg"

# VM to run tests with
export JT_JAVA=${OPENJDK_ROOT}/jdks/sapmachine25

export PATH=${OPENJDK_ROOT}/jtreg-prebuilt/${JTREG_VERSION}/bin/:$PATH

