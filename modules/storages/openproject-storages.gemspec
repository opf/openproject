# The comments in the files of this module will try to lift you from a
# beginner's level to an intermediary level of Ruby on Rails in the context of
# OpenProject.
#
# After reviewing this plugin, you will probably be able to create new plugins
# yourself and perform small to medium extensions of OpenProject.
#
# Preconditions:
#
# - You are familiar with the Ruby language. If not,
#   https://www.ruby-lang.org/en/documentation/quickstart/ may be a good place
#   to start.
#
# - You are familiar with the basic Rails concepts, meaning you're able to build
#   a basic application like a blog with post: you know what are models,
#   controllers, views, database migrations, etc.
#
# - You are familiar with Ruby on Rails guides available on
#   https://guides.rubyonrails.org/. You have read and practiced most of them
#   (except for the last sections on Extending Rails, Contributions, Policies
#   and Release Notes) and know how to look them up for information.
#
# - You have an OpenProject development environment set up. If not, use
#   https://www.openproject.org/docs/development/#additional-resources to
#   prepare one.
#
# - Frank Bergmann has put together additional tips and tricks on how to setup a
#   development environment and to get started developing
#
# Other good resources:
# - Modules vs. Classes:
#   https://medium.com/rubycademy/modules-in-ruby-part-i-a2cdfaccdb6e and
#   Explains the concepts of module (vs. class) and mixing, together with the
#   keywords module, include, prepend and extend.
# - Mixins and Modules:
#   https://blog.appsignal.com/2021/01/13/using-mixins-and-modules-in-your-ruby-on-rails-application.html

# Used by: OpenProject plugin architecture
# Purpose: Defines the metadata for the module
# References: https://guides.rubygems.org/specification-reference/
# rubocop:disable Gemspec/RequireMFA
Gem::Specification.new do |s|
  s.name        = "openproject-storages"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Storages"
  s.description = "Allows linking work packages to files in external storages, such as Nextcloud."
  s.license     = "GPLv3"
  s.files = Dir["{app,config,db,lib}/**/*"]
end
# rubocop:enable Gemspec/RequireMFA
