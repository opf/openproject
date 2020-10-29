# This rack app returns an invalid status code, which will cause
# Rack::Lint to throw an exception if it is present.  This
# is used to check whether Rack::Lint is in the stack or not.

run lambda {|env| return [42, {}, ["Rack::Lint wasn't there if you see this"]]}
