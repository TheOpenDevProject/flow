#!/bin/bash -e

# make sure -x (debugging) is off so we don't print the token in the logs
set +x

PAGES_CHECKOUT="$HOME/flowtype.org"
export BUNDLE_GEMFILE="${TRAVIS_BUILD_DIR}/website/Gemfile"

printf "travis_fold:start:installing_ruby\nInstalling Ruby\n"
source "$HOME/.rvm/scripts/rvm"
rvm use 2.2 --install --binary
gem install --no-rdoc --no-ri bundler
printf "travis_fold:end:installing_ruby\n"

printf "travis_fold:start:installing_jekyll\nInstalling Jekyll\n"
bundle install
printf "travis_fold:end:installing_jekyll\n"

printf "travis_fold:start:jekyll_build\nBuilding Jekyll site\n"
GEN_DIR=$([[ "$TRAVIS_TAG" = "" ]] && echo "master" || echo "$TRAVIS_TAG")
mkdir -p "$PAGES_CHECKOUT"
mkdir -p "website/_assets/gen/${GEN_DIR}"
mkdir -p "website/static/$GEN_DIR"
cp "bin/flow.js" "website/_assets/gen/${GEN_DIR}/flow.js"
cp -r "lib" "website/static/${GEN_DIR}/flowlib"
echo "version" > "website/_data/flow_dot_js_versions.csv"
git ls-remote --tags | awk '{print $2}' | cut -d/ -f3 | \
  grep -e '^v[0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}$' | \
  sort -s -t. -k 1,1nr -k 2,2nr -k 3,3nr | \
  head -n 5 >> "website/_data/flow_dot_js_versions.csv"
env \
  PATH="${TRAVIS_BUILD_DIR}/bin:$PATH" \
  bundle exec jekyll build -s website/ -d "$PAGES_CHECKOUT" --verbose
printf "travis_fold:end:jekyll_build\n"

printf "travis_fold:start:push_s3\nPushing to S3\n"
bundle exec s3_website push --config-dir=website/ --site="$PAGES_CHECKOUT"
printf "travis_fold:end:push_s3\n"
