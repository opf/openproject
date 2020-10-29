#!/usr/bin/ruby -n
# -*- encoding: binary -*-

BEGIN { $tests = $assertions = $failures = $errors = 0 }

$_ =~ /(\d+) tests, (\d+) assertions, (\d+) failures, (\d+) errors/ or next
$tests += $1.to_i
$assertions += $2.to_i
$failures += $3.to_i
$errors += $4.to_i

END {
  printf("\n%d tests, %d assertions, %d failures, %d errors\n",
         $tests, $assertions, $failures, $errors)
}
