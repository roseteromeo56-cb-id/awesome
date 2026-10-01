#!/usr/bin/env bash
set -euo pipefail

normalize_repo_url() {
	local candidate=$1
	local github_repo_url='^https://github\.com/[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]+#readme$'

	if [[ ! $candidate =~ $github_repo_url ]]; then
		return 1
	fi

	printf '%s\n' "${candidate%#readme}"
}

extract_repo_to_lint() {
	local line
	local candidate

	while IFS= read -r line; do
		[[ $line == +* ]] || continue
		[[ $line != +++* ]] || continue

		while IFS= read -r candidate; do
			normalize_repo_url "$candidate" && return 0
		done < <(printf '%s\n' "${line#+}" | grep -Eo 'https://[^[:space:])>]+' || true)
	done
}

run_linter() {
	local base_ref=${BASE_REF:-origin/main}
	local repo_to_lint
	local clone_dir

	repo_to_lint=$(git diff "$base_ref" -- readme.md | extract_repo_to_lint || true)

	if [[ -z $repo_to_lint ]]; then
		echo "No new GitHub link found in the format: https://github.com/owner/repo#readme"
		return 0
	fi

	clone_dir=$(mktemp -d)
	trap 'rm -rf "$clone_dir"' EXIT

	echo "Cloning $repo_to_lint"
	git clone --depth 1 --single-branch -- "$repo_to_lint" "$clone_dir"
	npm exec --yes --package=awesome-lint -- awesome-lint "$clone_dir/readme.md"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	run_linter
fi
