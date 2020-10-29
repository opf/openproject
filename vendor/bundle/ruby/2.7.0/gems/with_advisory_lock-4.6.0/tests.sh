#!/bin/bash -e
export DB

for RUBY in 2.4.0 jruby-1.7.13 ; do
  rbenv local $RUBY
  for DB in mysql postgresql sqlite ; do
    echo "$DB | $(ruby -v)"
#    appraisal bundle update
    appraisal rake test --verbose
  done
done
