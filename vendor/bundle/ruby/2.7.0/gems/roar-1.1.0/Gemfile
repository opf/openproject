source "http://rubygems.org"

# Specify your gem's dependencies in roar.gemspec
gemspec

install_if -> { RUBY_VERSION > '2.2.2' } do
  gem 'sinatra',          '~> 2.0.0.beta2'
  gem 'sinatra-contrib',  github: 'sinatra/sinatra'
end

gem 'nokogiri', '~> 1.6.8'

# gem "representable", path: "../representable"
# gem "representable", github: "apotonick/representable"
# gem "declarative", path: "../declarative"
gem "minitest-line"
gem "pry"
