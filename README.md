# Github Action: Maven Version Bump

A simple GitHub Action to automatically bump the version in a Maven `pom.xml` file based on commit messages.

## Features

- Automatically increments the major, minor, or patch version based on keywords in commit messages
- Customizable tag prefix for Git tags
- Patch default if no keywords are found

## Inputs

| Name               | Description                                                                             | Required | Default                                      |
|--------------------|-----------------------------------------------------------------------------------------|:--------:|----------------------------------------------|
| `pom_path`         | Path to the `pom.xml` file to update. Example: `./backend/pom.xml`                      |    No    | `pom.xml`                                    |
| `major_keyword`    | Comma-separated keywords that trigger a major version bump (e.g. BREAKING-CHANGE,major) |    No    | `major`                                      |
| `minor_keyword`    | Comma-separated keywords that trigger a minor version bump (e.g. feature,minor)         |    No    | `minor`                                      |
| `patch_keyword`    | Comma-separated keywords that trigger a patch version bump (e.g. chore,fix)             |    No    | `patch`                                      |
| `default_to_patch` | If set to `true`, a patch bump is performed if no keyword is found in commit messages   |    No    | `false`                                      |
| `tag_prefix`       | Prefix to use for the created git tag (e.g., `v` for tags like `v1.2.3`)                |    No    | `v`                                          |
| `git_user_name`    | Name of the git user for committing changes e.g. `MiHechtel`                            |    No    | `${ github.actor }`                          |
| `git_user_email`   | Email of the git user for committing changes e.g. `MiHechtel@noreply.github.com`        |    No    | `${ github.actor }@users.noreply.github.com` |

## Outputs

| Name             | Description                                                        |
|------------------|--------------------------------------------------------------------|
| `new_version`    | The new version number in `pom.xml` after the bump (e.g., `1.2.4`) |
| `bump_performed` | Boolean to indicate if version was bumped                          |

## Example Usage

```yaml
name: Version Bump

on:
  push:
    branches:
      - main

jobs:
  bump-version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Bump Version
        uses: MiHechtel/github-maven-bump@latest
        with:
          pom_path: './pom.xml'
          major_keyword: 'BREAKING CHANGE,major'
          minor_keyword: 'feat,minor'
          patch_keyword: 'fix,patch'
          default_to_patch: 'true'
          tag_prefix: 'service@'