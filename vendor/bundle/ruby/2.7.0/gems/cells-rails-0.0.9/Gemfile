source 'https://rubygems.org'

# Specify your gem's dependencies in cells-rails.gemspec
gemspec

# gem "my_engine", path: "engines/my_engine"

# gem 'sass-rails', "~> 4.0.3"#, "  ~> 3.1.0"
# gem "sprockets", "~> 2.12.3"

rails_version = ENV['RAILS_VERSION'] || '5.0'
gem "railties", "~> #{rails_version}"
gem "activerecord", "~> #{rails_version}"

gem "my_engine", path: "test/rails#{rails_version}/engines/my_engine"

group :development, :test do
  gem "minitest-spec-rails"
  gem "capybara_minitest_spec"
end

gem "simple_form"
gem "formtastic"
