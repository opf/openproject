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

# Improves handling of some edge cases when to_url is called. The method is provided by
# stringex but some edge cases have not been handled properly by that gem.
#
# This includes
#   * the strings '.' and '!' which would lead to an empty string otherwise

module OpenProject
  module ActsAsUrl
    module Adapter
      class OpActiveRecord < Stringex::ActsAsUrl::Adapter::ActiveRecord
        ##
        # Avoid generating the slug if the attribute is already set
        # and only_when_blank is true
        def ensure_unique_url!(instance)
          attribute = instance.send(settings.url_attribute)
          super if attribute.blank? || !settings.only_when_blank
        end

        ##
        # Always return the stored url, even if it has errors
        def url_attribute(instance)
          read_attribute instance, settings.url_attribute
        end

        private

        def modify_base_url
          root = instance.send(settings.attribute_to_urlify).to_s
          locale = configuration.settings.locale || :en
          self.base_url = root.to_localized_slug(locale:, **configuration.string_extensions_settings)

          modify_base_url_custom_rules if base_url.empty?
        end

        def modify_base_url_custom_rules
          replacement = case instance.send(settings.attribute_to_urlify).to_s
                        when "."
                          "dot"
                        when "!"
                          "bang"
                        end

          self.base_url = replacement if replacement
        end
      end
    end
  end
end
