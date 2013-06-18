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
