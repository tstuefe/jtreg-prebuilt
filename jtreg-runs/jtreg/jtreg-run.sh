#! /bin/bash
set -e

OPENJDK_ROOT="/shared/projects/openjdk"

if [ $# != 3 ]; then
	echo "Usage: jtreg-run.sh <codeline> <what> <test>"
	echo "   eg: jtreg-run.sh jdk-jdk fastdebug runtime/Vitals"
	exit -1
fi

OUTPUT_DIR="${OPENJDK_ROOT}/${1}/output-${2}"
JDK_DIR="${OUTPUT_DIR}/images/jdk"
NATIVES_DIR="${OUTPUT_DIR}/images/test/hotspot/jtreg/native"
JTREG_TEST="${OPENJDK_ROOT}/${1}/source/test/hotspot/jtreg/${3}"
PROBLEMLIST="${OPENJDK_ROOT}/${1}/source/test/hotspot/jtreg/ProblemList.txt"

echo "jtreg -retain -conc:4 -jdk:${JDK_DIR} -nativepath:${NATIVES_DIR} -exclude:${PROBLEMLIST}  ${JTREG_TEST}"
jtreg -retain -conc:4 -jdk:${JDK_DIR} -nativepath:${NATIVES_DIR}  -exclude:${PROBLEMLIST} ${JTREG_TEST}
