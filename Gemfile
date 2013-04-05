source "http://rubygems.org"

gemspec

if ENV['RAILS_ROOT']
  eval(IO.read("#{ENV['RAILS_ROOT']}/Gemfile"), binding)
else
  puts "Host application dependencies not loaded. If you plan to run cucumber tests, specify env variable RAILS_ROOT."
end