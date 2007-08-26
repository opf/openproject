require 'redmine/version'
require 'redmine/mime_type'
require 'redmine/acts_as_watchable/init'

begin
  require_library_or_gem 'rmagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

REDMINE_SUPPORTED_SCM = %w( Subversion Darcs Mercurial Cvs )
