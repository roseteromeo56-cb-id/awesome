#!/usr/bin/env bash
set -euo pipefail

found=0

while IFS= read -r -d '' workflow; do
	if ! grep -Eq '^[[:space:]]*pull_request:' "$workflow"; then
		continue
	fi

	while IFS=: read -r line_number line; do
		if [[ "$line" =~ (^|[[:space:]])(\./|[A-Za-z0-9_.-]+/)[^[:space:]]+\.sh([[:space:]]|$) ]]; then
			printf 'CRITICAL %s:%s pull_request workflow runs a repo-local shell script from checked-out PR content: %s\n' "$workflow" "$line_number" "$line"
			found=1
		fi
	done < <(grep -nE '(^|[[:space:]])(\./|[A-Za-z0-9_.-]+/)[^[:space:]]+\.sh([[:space:]]|$)' "$workflow" || true)
done < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print0)

if [ "$found" -ne 0 ]; then
	exit 1
fi

echo "No critical pull_request workflow local-script execution findings."
