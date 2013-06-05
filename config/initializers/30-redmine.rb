#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

I18n.default_locale = 'en'
# Adds fallback to default locale for untranslated strings
if Setting.table_exists? # don't want to prevent migrations
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.fallbacks.defaults = [I18n.default_locale] + Setting.available_languages.map(&:to_sym)
end

require 'redmine'
require 'chili_project'
