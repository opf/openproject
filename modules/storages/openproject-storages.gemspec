# This is the first file in the storages plugin, so I'll use # it to
# include some general comments (ToDo: Move this into a separate
# file?).
# With the comments in this file we try to lift you from a beginner's
# level to an intermediary level of Ruby on Rails in the context of
# OpenProject.
# After reviewing this plugin, you will probably be able to create new
# plugins yourself and to perform small to medium extensions of OpenProject.
# Preconditions:
# - We assume that you are more or less familiar with the Ruby
#   language. If not, please check: ToDo: Ruby tutorial
# - We also assume that you are familiar with the basic Rails concepts
#   and that you have built the usual toy application (blog with
#   posts) yourself. So you know what is a model, a controller, a view,
#   a database migration etc.
# - Just go to https://guides.rubyonrails.org/
#   and read and practice most of the guides, except for the last sections
#   on Extending Rails, Contributions, Policies and Release Notes.
# - Frank Bergmann has put together some tips and tricks on how to setup
#   a development environment and to get started developing:
#   ToDo: Publish PPTs
#
# ToDo: Copy /db/ and migrations from the global application to a local
# ./db/ folder?
#
# Other good resources:
# - Modules vs. Classes:
#   https://medium.com/rubycademy/modules-in-ruby-part-i-a2cdfaccdb6e and
#   Explains the concepts of module (vs. class) and mixing, together with
#   the keywords module, include, prepend and extend.
# - Mixins and Modules:
#   https://blog.appsignal.com/2021/01/13/using-mixins-and-modules-in-your-ruby-on-rails-application.html
#
#
# Used by: OpenProject package manager(?)
# Purpose: Defines the metadata for the module
# References: https://guides.rubygems.org/specification-reference/
Gem::Specification.new do |s|
  s.name        = 'openproject-storages'
  s.version     = '1.0.0'
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.summary     = 'OpenProject Storages'
  s.description = 'Allows linking work packages to files in external storages, such as Nextcloud.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*']
end
