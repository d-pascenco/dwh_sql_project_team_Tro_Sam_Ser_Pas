#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

if [ -z "$1" ]; then
    echo "Commit message is required"
    echo "Usage: ./scripts/git_push.sh \"your commit message\""
    exit 1
fi

git status
git add .
git commit -m "$1"
git push origin main
