# Copyright (c) 2005-2006 David Barri

require 'gloc'
require 'gloc-ruby'
require 'gloc-rails'
require 'gloc-rails-text'
require 'gloc-config'

require 'gloc-dev' if ENV['RAILS_ENV'] == 'development'

GLoc.load_gloc_default_localized_strings
