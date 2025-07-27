#!/bin/bash
set -euo pipefail

VERSION="$1"

if [[ -z "$VERSION" ]]; then
  echo "Missing chart version"
  exit 1
fi

# Update version field in Chart.yaml
yq e -i ".version = \"$VERSION\"" Chart.yaml
