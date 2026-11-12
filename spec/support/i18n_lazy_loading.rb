# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Enable translations lazy loading by default, except on CI where we want to
# have all translations loaded during application eager loading to be closer to
# production configuration.
return if ENV["CI"]

# Lazy loading translations avoids a 2 to 4 seconds penalty on first call to
# `I18n.translate` by loading only the translations for the current locale
# instead of loading them for all locales.
require "i18n/backend/lazy_loadable"

# Need to make LocaleExtractor recognize our js-<locale>.yaml file format
class I18n::Backend::LocaleExtractor
  def self.locale_from_path(path)
    name = File.basename(path, ".*")
    locale = name.split("_").first

    return if locale.nil?

    locale.delete_prefix("js-").delete_suffix(".seeders").to_sym
  end
end

I18n.backend = I18n::Backend::LazyLoadable.new(lazy_load: true)
