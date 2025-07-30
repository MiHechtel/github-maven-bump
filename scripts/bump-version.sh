#!/bin/bash
set -e

MAJOR_KEYWORDS="${MAJOR_KEYWORDS:-BREAKING CHANGE,major}"
MINOR_KEYWORDS="${MINOR_KEYWORDS:-feat,minor}"
PATCH_KEYWORDS="${PATCH_KEYWORDS:-fix,patch}"
DEFAULT_TO_PATCH="${DEFAULT_TO_PATCH:-true}"
TAG_PREFIX="${TAG_PREFIX:-v}"
POM_PATH="${POM_PATH:-pom.xml}"
GIT_USER_NAME="${GIT_USER_NAME:-${GITHUB_ACTOR:-github-actions[bot]}}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-${GITHUB_ACTOR:-github-actions[bot]}@users.noreply.github.com}"

COMMIT_MSG=$(git log -1 --pretty=%B | tr '[:upper:]' '[:lower:]')

IFS=',' read -ra MAJOR_ARR <<< "$MAJOR_KEYWORDS"
IFS=',' read -ra MINOR_ARR <<< "$MINOR_KEYWORDS"
IFS=',' read -ra PATCH_ARR <<< "$PATCH_KEYWORDS"

BUMP_TYPE=""

for kw in "${MAJOR_ARR[@]}"; do
  if [[ "$COMMIT_MSG" == *"${kw}"* ]]; then
    BUMP_TYPE="major"
    break
  fi
done

if [[ -z "$BUMP_TYPE" ]]; then
  for kw in "${MINOR_ARR[@]}"; do
    if [[ "$COMMIT_MSG" == *"${kw}"* ]]; then
      BUMP_TYPE="minor"
      break
    fi
  done
fi

if [[ -z "$BUMP_TYPE" ]]; then
  for kw in "${PATCH_ARR[@]}"; do
    if [[ "$COMMIT_MSG" == *"${kw}"* ]]; then
      BUMP_TYPE="patch"
      break
    fi
  done
fi

CURRENT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout -f "$POM_PATH")
if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Could not read current version from $POM_PATH."
  exit 1
fi

if [[ -z "$BUMP_TYPE" && "$DEFAULT_TO_PATCH" != "true" ]]; then
  echo "No bump type found and patch fallback is disabled."
  echo "new-version=$CURRENT_VERSION" >> "$GITHUB_OUTPUT"
  echo "bump-performed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

if [[ -z "$BUMP_TYPE" && "$DEFAULT_TO_PATCH" == "true" ]]; then
  BUMP_TYPE="patch"
fi

semver_bump() {
  local version="$1"
  local bump="$2"
  IFS='.' read -r major minor patch <<< "$version"
  case "$bump" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
  esac
  echo "${major}.${minor}.${patch}"
}

NEW_VERSION=$(semver_bump "$CURRENT_VERSION" "$BUMP_TYPE")

mvn --batch-mode versions:set -DnewVersion="$NEW_VERSION" -f "$POM_PATH"

git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
git add "$POM_PATH"
git commit -m "chore: bump pom.xml version from $CURRENT_VERSION to $NEW_VERSION"

TAG="${TAG_PREFIX}${NEW_VERSION}"
git tag "$TAG"
git push origin "$TAG"
git push origin HEAD

echo "new-version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
echo "bump-performed=true" >> "$GITHUB_OUTPUT"
