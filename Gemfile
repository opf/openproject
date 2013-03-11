source "http://rubygems.org"

# Declare your gem's dependencies in redmine-meeting.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.

gemspec

if ENV['RAILS_ROOT']
  eval(IO.read("#{ENV['RAILS_ROOT']}/Gemfile"), binding)
else
  puts "Host application dependencies not loaded. If you plan to run cucumber tests, specify env variable RAILS_ROOT."
end

