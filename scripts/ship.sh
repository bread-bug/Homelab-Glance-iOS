#!/usr/bin/env bash
# Dispatch a workflow only once GitHub's mirror actually has the commit we
# intend to build. workflow_dispatch builds whatever is on the branch at
# dispatch time, so firing before the push mirror catches up silently builds
# the previous commit.
set -euo pipefail

WORKFLOW="${1:-testflight}"
WANT="$(git rev-parse HEAD)"

echo "want: ${WANT:0:7} ($WORKFLOW)"

for _ in $(seq 1 60); do
    git fetch -q github main 2>/dev/null || true
    HAVE="$(git rev-parse github/main 2>/dev/null || echo none)"
    if [ "$HAVE" = "$WANT" ]; then
        echo "mirror synced"
        gh workflow run "$WORKFLOW"
        exit 0
    fi
    echo "mirror at ${HAVE:0:7}, waiting…"
    sleep 5
done

echo "mirror never caught up; not dispatching" >&2
exit 1
