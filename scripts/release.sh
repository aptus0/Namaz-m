#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Kullanim: $0 <patch|minor|major> \"commit mesaji\""
  exit 1
fi

bump_type="$1"
shift
commit_message="$*"

if [ ! -f VERSION ]; then
  echo "VERSION dosyasi bulunamadi."
  exit 1
fi

current_version="$(cat VERSION)"
IFS='.' read -r major minor patch <<<"$current_version"

if [ -z "${major:-}" ] || [ -z "${minor:-}" ] || [ -z "${patch:-}" ]; then
  echo "VERSION formati gecersiz: $current_version"
  exit 1
fi

case "$bump_type" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  *)
    echo "Gecersiz bump tipi: $bump_type"
    echo "Kullanim: $0 <patch|minor|major> \"commit mesaji\""
    exit 1
    ;;
esac

new_version="${major}.${minor}.${patch}"
echo "$new_version" > VERSION

git add -A

if git diff --cached --quiet; then
  echo "Commitlenecek degisiklik yok."
  exit 1
fi

git commit -m "$commit_message"
git tag -a "v${new_version}" -m "Version ${new_version}"

echo "Surum olusturuldu: v${new_version}"
