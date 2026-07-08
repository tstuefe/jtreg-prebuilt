#!/bin/bash
set -eu

# The following variables shall be set by the environment.
if [[ -z "$CODELINE_DEFAULT" || -z "$OPENJDK_ROOT" || -z "$JT_JAVA" ]]; then
    echo "env var missing";
    exit -1
fi

function printUsage() {
	local USAGE=`cat << EOM
Usage: $0
            --jdk|--hotspot           (defaults to hotspot)
		[-c|--codeline <codeline> (default "${CODELINE_DEFAULT}")]
		[-v|--version <version>   (default "fastdebug")]
		[--images-dir <path>      (default off)]
		[--dry-run                (default off)]
		[-c|--concurrency <concurrency> (default 8)]
		[--list]
		[--report]
		[--failed-only]
		[--notrun-only]
		[--manual-only]
		[--vmoptions <vm options>]
		[--extra-jtreg-options <extra jtreg options>]
		[--help]
		<test>|<testgroup>|ALL

Options:
  --jdk|--hotspot:  Select test suite (default: hotspot)
  -c|--codeline:    Codeline to test (default: "${CODELINE_DEFAULT}")
  -v|--version:     Build version (default: "fastdebug")
  --images-dir:     Override codeline/version, specify images directory directly
                    containing the testee jdk and the native test parts
  --dry-run:        Print command without executing
  -c|--concurrency: Number of concurrent tests (default: 8)
  --list:           Only list tests, don't run them
  --report:         Only generate report, don't run tests
  --failed-only:    Only run tests that failed
  --notrun-only:    Only run tests that haven't run yet
  --manual-only:    Only run manual tests (default: only run automatic tests)
  --vmoptions:      VM options to pass to test JVMs (e.g., "-Xmx4g -XX:+UseG1GC")
  --extra-jtreg-options: Additional jtreg options
  --help:           Show this help message
  <test>:           Test path relative to jtreg test root (e.g., "runtime/ErrorHandling")
  <testgroup>:      Test group with leading colon (e.g., ":tier1")
  ALL:              All tests (only valid with --report, --list, or filter options)

Examples:

  Run all tests in hotspot tier2
  $0 --hotspot :tier1
    or
  $0 :tier1

  (--hotspot can be omitted, its the default)

  Generate report (e.g. if run was interupted) in hotspot:
  $0 --report ALL
    
  Generate report (e.g. if run was interupted) in jdk:
  $0 --jdk --report ALL

  List all tests in hotspot tier2
  $0 --list :tier1

  List all failed tests in hotspot tier2:
  $0 --list --failed-only :tier2

  List all failed tests in jdk:
  $0 --jdk --list --failed-only ALL

  Repeat tests, but only retry failed tests, in hotspot tier1:
  $0 --failed-only :tier1

  Repeat tests, but only retry failed tests, in jdk:
  $0 --jdk --failed-only :tier1

  Continue running tests after tests were interrupted (e.g. next day), in hotspot, tier1:
  $0 --notrun-only :tier1

EOM
`
	echo "$USAGE"
}

# defaults
CODELINE="$CODELINE_DEFAULT"
VERSION="fastdebug"
HOTSPOT_OR_JDK="hotspot"
EXTRA_JTREG_OPTIONS=""
VMOPTIONS=""
CONCURRENCY="8"
DRY_RUN=0
TESTS=""
IMAGES_DIR=""
MANUAL_OR_AUTOMATIC="-automatic"

while [[ $# -gt 0 ]]; do
  case $1 in
    -C|--codeline)
      CODELINE="$2"
      shift # past argument
      shift # past value
      ;;
	-V|--version)
      VERSION="$2"
      shift # past argument
      shift # past value
      ;;
	--images-dir)
	  IMAGES_DIR="$2"
      shift # past argument
      shift # past value
      ;;
	--hotspot)
	  HOTSPOT_OR_JDK="hotspot"
	  shift # past argument
	  ;;
	--jdk)
	  HOTSPOT_OR_JDK="jdk"
	  shift # past argument
	  ;;
	--dry-run)
	  DRY_RUN=1
	  shift # past argument
	  ;;
	-c|--concurrency)
      CONCURRENCY="$2"
      shift # past argument
      shift # past value
      ;;
	--list)
      EXTRA_JTREG_OPTIONS="${EXTRA_JTREG_OPTIONS} -l"
      shift # past argument
      ;;
	--report)
	  EXTRA_JTREG_OPTIONS="${EXTRA_JTREG_OPTIONS} -ro"
      shift # past argument
      ;;
	--failed-only)
	  EXTRA_JTREG_OPTIONS="${EXTRA_JTREG_OPTIONS} -status:error|failed"
      shift # past argument
      ;;
	--notrun-only)
	  EXTRA_JTREG_OPTIONS="${EXTRA_JTREG_OPTIONS} -status:notRun"
      shift # past argument
      ;;
	--manual-only)
	  MANUAL_OR_AUTOMATIC="-manual"
	     shift # past argument
	     ;;
	--vmoptions)
	  VMOPTIONS="-vmoptions:$2"
	     shift # past argument
	     shift # past value
	     ;;
	--extra-jtreg-options)
	  EXTRA_JTREG_OPTIONS="${EXTRA_JTREG_OPTIONS} $2"
	     shift # past argument
	     shift # past value
	     ;;
	--help|-h)
	  printUsage
	  exit 0
	  ;;
	   -*|--*)
	     echo "Unknown option $1"
	  printUsage
	     exit 1
	     ;;
    *)
      TESTS="${TESTS} ${1}"
      shift # past argument
      ;;
  esac
done

if [ -z "$TESTS" ]; then
	echo "No tests given"
	printUsage
	exit -1;
fi

if [ "$HOTSPOT_OR_JDK" == "hotspot" ]; then
	echo "Hotspot mode"
	JTREG_TEST_ROOT="test/hotspot/jtreg"
	NATIVES_DIR_SUB="test/hotspot/jtreg/native"
elif [ "$HOTSPOT_OR_JDK" == "jdk" ]; then
	echo "jdk mode"
	JTREG_TEST_ROOT="test/jdk"
	NATIVES_DIR_SUB="test/jdk/jtreg/native"
else
	echo "Unknown mode"
	exit -1;
fi

OPENJDK_ROOT="/shared/projects/openjdk"

if [ -z $IMAGES_DIR ]; then
	IMAGES_DIR="${OPENJDK_ROOT}/${CODELINE}/output-${VERSION}/images"
fi

if [  ! -d "${IMAGES_DIR}" ]; then
	echo "${IMAGES_DIR} does not exist"
	exit -1;
fi

TESTEE_JDK_DIR="${IMAGES_DIR}/jdk"

NATIVE_PATH="${IMAGES_DIR}/${NATIVES_DIR_SUB}"

PROBLEMLIST="${OPENJDK_ROOT}/${CODELINE}/source/${JTREG_TEST_ROOT}/ProblemList.txt"

echo "Codeline: ${CODELINE}"
echo "Version: ${VERSION}"
echo "Testee: ${TESTEE_JDK_DIR}"
echo "Native Path: ${NATIVE_PATH}"
echo "Extra jtreg options: ${EXTRA_JTREG_OPTIONS}"
echo ""

for TEST in $TESTS; do

	# Process each test input, then start test
	if [ "${TEST}" == "ALL" ]; then
		if [ -z $EXTRA_JTREG_OPTIONS ]; then
			echo "ALL not allowed for run mode"
			printUsage
			exit -1;
		fi
		JTREG_TEST="${OPENJDK_ROOT}/${CODELINE}/source/${JTREG_TEST_ROOT}"
	elif [[ ${TEST} == :* ]]; then
		# group
		JTREG_TEST="${OPENJDK_ROOT}/${CODELINE}/source/${JTREG_TEST_ROOT}${TEST}"
	else
		# individual test(s)
		JTREG_TEST="${OPENJDK_ROOT}/${CODELINE}/source/${JTREG_TEST_ROOT}/${TEST}"
	fi

	# Note: 
	# -automatic is needed to skip manual tests. Forgetting it may cause hangs at the first "endless"
	#  manual test (e.g. TestCheckedReleaseCriticalArray)
	# -retain to retain test files for later analysis

	# Build command as array to properly handle arguments with spaces
	COMMAND=(jtreg -J-Djavatest.maxOutputSize=2000000 -retain ${MANUAL_OR_AUTOMATIC} -conc:${CONCURRENCY} -jdk:${TESTEE_JDK_DIR} -nativepath:${NATIVE_PATH} -exclude:${PROBLEMLIST})
	
	# Add vmoptions if specified (as single argument)
	if [ -n "$VMOPTIONS" ]; then
		COMMAND+=("${VMOPTIONS}")
	fi
	
	# Add extra jtreg options and test
	COMMAND+=(${EXTRA_JTREG_OPTIONS} ${JTREG_TEST})

	# Print command with proper quoting to show what will be executed
	printf '%q ' "${COMMAND[@]}"
	echo

	if [[ $DRY_RUN == 1 ]]; then
		echo "dry run - good bye"
	else
		# switch off error state lest it stops if the first in a series of tests had jtreg return an error code (eg no tests selected causes that)
		set +e
		time "${COMMAND[@]}"
		set -e
	fi

done

