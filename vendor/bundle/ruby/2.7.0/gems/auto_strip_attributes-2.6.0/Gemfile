source "http://rubygems.org"

# Specify your gem's dependencies in auto_strip_attributes.gemspec
gemspec


# For travis testing
# http://schneems.com/post/50991826838/testing-against-multiple-rails-versions
rails_version = ENV["RAILS_VERSION"] || "default"

case rails_version
  when "default"
    gem "rails"
  else
    gem "rails", "~> #{rails_version}"
  end


