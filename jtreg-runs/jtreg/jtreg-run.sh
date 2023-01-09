#! /bin/bash
set -e

if [ $# != 3 ]; then
	echo "Usage: jtreg-run.sh <codeline> <what> <test>"
	echo "   eg: jtreg-run.sh jdk-jdk fastdebug runtime/Vitals"
	exit -1
fi

OUTPUT_DIR="/shared/projects/openjdk/${1}/output-${2}"
JDK_DIR="${OUTPUT_DIR}/images/jdk"
NATIVES_DIR="${OUTPUT_DIR}/images/test/hotspot/jtreg/native"
JTREG_TEST="/shared/projects/openjdk/${1}/source/test/hotspot/jtreg/${3}"

echo "jtreg -retain -conc:4 -jdk:${JDK_DIR} -nativepath:${NATIVES_DIR} ${JTREG_TEST}"
jtreg -retain -conc:4 -jdk:${JDK_DIR} -nativepath:${NATIVES_DIR} ${JTREG_TEST}
