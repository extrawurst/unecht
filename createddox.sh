#!/bin/bash -e

# Settings
REPO_PATH=git@github.com:Extrawurst/unecht.git
HTML_PATH=~/doc-repo
COMMIT_USER="doc-builder"
COMMIT_EMAIL="travis@travis-ci.com"
CHANGESET=$(git rev-parse --verify HEAD)

# Get a clean version of the HTML documentation repo.
rm -rf ${HTML_PATH}
mkdir -p ${HTML_PATH}
git clone -b gh-pages "${REPO_PATH}" --single-branch ${HTML_PATH}

# rm all the files through git to prevent stale files.
cd ${HTML_PATH}
git rm -rf .
cd -

# build docs.json
dub build --config=ddox -f

# copy
cp -r ddox/ ${HTML_PATH}/

# create html
cd subtrees/scod
dub build
./scod generate-html ../../docs.json ${HTML_PATH}

# Create and commit the documentation repo.
cd ${HTML_PATH}
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
git commit -m "Automated documentation build for changeset ${CHANGESET}."
git push origin gh-pages
cd -
