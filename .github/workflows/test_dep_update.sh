#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gh jq
set -e
echo "$GITHUB_API_TOKEN" | gh auth login --with-token
git branch -d depupdate || true
git branch depupdate
git checkout depupdate
json="$(gh pr list --search "author:app/github-actions" --json headRefName,number)"
echo "$json" | jq '.[] | .headRefName | @text' | xargs -L1 -- git pull --rebase origin
if nix flake check; then
    echo "$json" | jq ".[] | .number | @text" | xargs -L1 -- gh pr merge --squash --delete-branch
else
    gh issue create \
        --title "Recent Dependency update PRs failing tests" \
        --body "I tried to combine these PRs and they failed the test: $(echo "$json" | jq ".[] | .number | @text" | xargs echo '#')"
fi
