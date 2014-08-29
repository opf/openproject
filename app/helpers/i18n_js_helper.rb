#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module I18nJsHelper
  def i18n_js_tags
    fallbacks = I18n.fallbacks[I18n.locale].map(&:to_s)
    fallbacks.shift

    s = ""
    s << javascript_include_tag("i18n")
    s << javascript_include_tag("i18n/translations")
    s << javascript_tag(%Q{
      I18n.defaultLocale = "#{I18n.default_locale}";
      I18n.locale        = "#{I18n.locale}";
      I18n.fallbacks     = true;
      I18n.fallbackRules = I18n.fallbackRules || {};
      I18n.fallbackRules['#{I18n.locale}'] = #{fallbacks.to_json};
    })
    s
  end
end
