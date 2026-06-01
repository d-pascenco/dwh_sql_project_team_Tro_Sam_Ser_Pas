#!/bin/bash

set -e

source git_config.env

git pull "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/d-pascenco/dwh_sql_project_team_Tro_Sam_Ser_Pas.git" "$GIT_BRANCH"
