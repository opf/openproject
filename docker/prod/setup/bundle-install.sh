#!/bin/bash

set -e

bundle config set --local path 'vendor/bundle'
bundle config set --local without 'test development'
bundle install --jobs=8 --retry=3
# Use bundle clean to force remove gem versions the Gemfile.lock does not depend on
bundle clean --force
bundle config set deployment 'true'
cp Gemfile.lock Gemfile.lock.bak
rm -rf vendor/bundle/ruby/*/cache
rm -rf vendor/bundle/ruby/*/gems/*/spec
rm -rf vendor/bundle/ruby/*/gems/*/test
rm -rf vendor/bundle/ruby/*/gems/*/tests
rm -rf vendor/bundle/ruby/*/gems/*/{doc,docs,example,examples,benchmark,benchmarks}
rm -rf vendor/bundle/ruby/*/bundler/gems/*/.git
rm -rf vendor/bundle/ruby/*/bundler/gems/*/{spec,test,tests,doc,docs,example,examples,benchmark,benchmarks}
find vendor/bundle -type f \( -name '*.a' -o -name '*.o' \) -delete
