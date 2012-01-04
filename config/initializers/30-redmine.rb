#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

I18n.default_locale = 'en'
# Adds fallback to default locale for untranslated strings
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

require 'redmine'
require 'chili_project'
