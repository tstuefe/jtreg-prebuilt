#!/bin/bash
# Unpacks all jtreg variants to their respective folders


set -euo pipefail

trap 'echo "Error on line $LINENO (exit code $?)" >&2' ERR

for a in jtreg-*.tar.gz; do tar -xf $a; mv jtreg ${a/\.tar\.gz//}; done
for a in jtreg-*.zip; do unzip $a; mv jtreg ${a/\.zip//}; done

