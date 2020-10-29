source 'https://rubygems.org'

gemspec

group :test do
  platforms :mri do
    gem 'codeclimate-test-reporter', require: false
    gem 'simplecov', require: false
  end
end

group :tools do
  gem 'rubocop'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen', '3.0.6'
  gem 'pry-byebug', platform: :mri
end
