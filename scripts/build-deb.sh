#!/bin/bash
# Build Debian package via GitHub Actions and download the result.
set -e

REPO="cylonix/cylonix"
WORKFLOW="build-deb.yml"
ARTIFACT="cylonix-deb"
BRANCH="${1:-$(git branch --show-current)}"
OUT_DIR="${2:-build/linux/x64/release}"

echo "Triggering build-deb workflow on branch: ${BRANCH}"
gh workflow run "${WORKFLOW}" --repo "${REPO}" --ref "${BRANCH}" --field branch="${BRANCH}"

# Wait for the run to start (it takes a few seconds to appear)
echo "Waiting for run to start..."
sleep 5

RUN_ID=$(gh run list --repo "${REPO}" --workflow="${WORKFLOW}" --limit 1 --json databaseId -q '.[0].databaseId')
echo "Run ID: ${RUN_ID}"
echo "Watching: https://github.com/${REPO}/actions/runs/${RUN_ID}"

gh run watch "${RUN_ID}" --repo "${REPO}"

echo ""
STATUS=$(gh run view "${RUN_ID}" --repo "${REPO}" --json conclusion -q .conclusion)
if [ "${STATUS}" != "success" ]; then
    echo "Build failed (conclusion: ${STATUS}). Check logs above."
    exit 1
fi

mkdir -p "${OUT_DIR}"
echo "Downloading artifact to ${OUT_DIR}/"
gh run download "${RUN_ID}" --repo "${REPO}" --name "${ARTIFACT}" --dir "${OUT_DIR}"
echo ""
echo "Done:"
ls -lh "${OUT_DIR}"/cylonix*.deb 2>/dev/null || ls -lh "${OUT_DIR}"/
