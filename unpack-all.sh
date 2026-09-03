#!/bin/bash
# Unpacks all jtreg variants to their respective folders


set -euo pipefail

trap 'echo "Error on line $LINENO (exit code $?)" >&2' ERR

for a in jtreg-*.tar.gz; do
	into="${a/\.tar\.gz//}";
	if [[ -d "$into" ]]; then
		echo "already exists"
	fi
	tar -xf $a; mv jtreg $into;
done

for a in jtreg-*.zip; do
	into="${a/\.zip//}";
	if [[ -d "$into" ]]; then
		echo "already exists"
	fi
	tar -xf $a; mv jtreg $into;
done


