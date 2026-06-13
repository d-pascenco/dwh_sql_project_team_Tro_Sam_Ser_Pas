#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

source "$PROJECT_DIR/git_config.env"

git pull "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/d-pascenco/dwh_sql_project_team_Tro_Sam_Ser_Pas.git" "$GIT_BRANCH"