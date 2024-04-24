# Multi_json issue #208 https://github.com/intridea/multi_json/issues/208
# produces a `NoMethodError` with some tests like
# modules/bim/spec/requests/api/bcf/v2_1/viewpoints_api_spec.rb:277 where grape
# is calling multi_json with a specific adapter. It will fail if it is the first
# test executed.
#
# Calling this will prevent the error from happening
MultiJson::OptionsCache.reset

# This file can be removed once the issue has been fixed and released in a new
# version of multi_json gem (issue exists in 1.15.0)
