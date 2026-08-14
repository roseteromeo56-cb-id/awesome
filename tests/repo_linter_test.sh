#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../.github/workflows/repo_linter.sh"

assert_extracts() {
	local expected=$1
	local diff=$2
	local actual

	actual=$(printf '%s\n' "$diff" | extract_repo_to_lint || true)

	if [[ $actual != "$expected" ]]; then
		printf 'Expected: %s\nActual:   %s\n' "$expected" "$actual" >&2
		return 1
	fi
}

assert_rejects() {
	local diff=$1
	local actual

	actual=$(printf '%s\n' "$diff" | extract_repo_to_lint || true)

	if [[ -n $actual ]]; then
		printf 'Expected URL to be rejected, got: %s\n' "$actual" >&2
		return 1
	fi
}

assert_extracts \
	'https://github.com/example/awesome-list' \
	'+- [Example](https://github.com/example/awesome-list#readme) - Example project.'

assert_rejects \
	'+- [Example](https://evil.example/example/awesome-list#readme) - Example project.'

assert_rejects \
	'+- [Example](https://github.com/example/awesome-list/issues/1#readme) - Example project.'

assert_rejects \
	'+- [Example](https://github.com/example/awesome-list#readme?token=secret) - Example project.'

assert_rejects \
	'+- [Example](https://github.com@example.invalid/example/awesome-list#readme) - Example project.'

assert_rejects \
	'+++ b/readme.md'

if ! grep -Fq 'git clone --depth 1 --single-branch -- "$repo_to_lint" "$clone_dir"' .github/workflows/repo_linter.sh; then
	printf 'Expected git clone to use -- before the repository URL\n' >&2
	exit 1
fi

if ! grep -Fq 'npm exec --yes --package=awesome-lint -- awesome-lint "$clone_dir/readme.md"' .github/workflows/repo_linter.sh; then
	printf 'Expected awesome-lint to be selected explicitly outside the cloned repository\n' >&2
	exit 1
fi

printf 'repo_linter tests passed\n'
