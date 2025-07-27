#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Version not passed"
  exit 1
fi

CHART_FILE="Chart.yaml"

if [ ! -f "$CHART_FILE" ]; then
  echo "$CHART_FILE not found"
  exit 1
fi

# Update version in Chart.yaml
yq e -i ".version = \"$VERSION\"" "$CHART_FILE"
