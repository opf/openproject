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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Restricts loaded locales to :en to avoid a 2-seconds penalty when locales are
# loaded.
#
# Disable with +TEST_NO_I18N_LAZY_LOADING+ env variable.
module I18nLazyLoading
  # Load additional locales when calling:
  #
  # - +Redmine::I18n#all_attribute_translations+
  # - +Redmine::I18n#ll+
  module RedmineI18nPatch
    def all_attribute_translations(locale)
      I18nLazyLoading.load_locale(locale)
      super
    end
  end

  # Load additional locales when calling:
  #
  # - +I18n.locale=+
  # - +Stringex::Localization.locale=+
  module I18nPatch
    def locale=(locale)
      I18nLazyLoading.load_locale(locale)
      super
    end

    def t(*args, **options)
      I18nLazyLoading.load_locale(options[:locale]) if options[:locale]
      super
    end
  end

  def self.install
    return if ENV["TEST_NO_I18N_LAZY_LOADING"].present?

    # copy original I18n load path
    @@original_load_path = I18n.config.load_path.dup
    # restrict available locales to :en
    I18n.config.load_path = load_path(:en)

    # patch to load locales on demand
    Redmine::I18n.prepend(RedmineI18nPatch)
    I18n.singleton_class.prepend(I18nPatch)
    Stringex::Localization.singleton_class.prepend(I18nPatch)
  end

  def self.load_locale(locale)
    return if locale.nil?
    return if ::I18n.config.available_locales_set.include?(locale)

    I18n.backend.load_translations(load_path(locale))
    I18n.config.clear_available_locales_set
  end

  def self.load_path(locale)
    file_regex = /\/(js-)?#{locale}[.a-z]+$/i
    @@original_load_path.grep(file_regex)
  end
end

RSpec.configure do
  I18nLazyLoading.install
end
