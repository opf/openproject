#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    # Since APIv3 uses different names for some properties, there is sometimes the need to convert
    # names between the "old" Rails/ActiveRecord world of names and the "new" APIv3 world of names.
    # This class provides methods to cope with the neccessary name conversions
    # There are multiple reasons for naming differences:
    #  - APIv3 is using camelCase as opposed to snake_case
    #  - APIv3 defines some properties as a different type, which requires a name change
    #     e.g. estimatedTime vs estimated_hours (AR: hours; API: generic duration)
    #  - some names used in AR are even there kind of deprecated
    #     e.g. version, which everyone refers to as version
    #  - some names in AR are plainly inconsistent, whereas the API tries to be as consistent as
    #    possible, e.g. updated_at vs updated_on
    #
    # Callers note: While this class is envisioned to be generally usable, it is currently solely
    # used for purposes around work packages. Further work might be required for conversions to make
    # sense in different contexts.
    class PropertyNameConverter
      class << self
        # Converts the attribute name as referred to by ActiveRecord to a corresponding API-conform
        # attribute name:
        #  * camelCasing the attribute name
        #  * unifying :status and :status_id to 'status' (and other foo_id fields)
        #  * converting totally different attribute names (e.g. createdAt vs createdOn)
        def from_ar_name(attribute)
          attribute = normalize_foreign_key_name attribute
          attribute = expand_custom_field_name attribute

          special_conversion = Constants::ARToAPIConversions.all[attribute.to_sym]
          return special_conversion if special_conversion

          # use the generic conversion rules if there is no special conversion
          attribute.camelize(:lower)
        end

        # Converts the attribute name as referred to by the APIv3 to the source name of the attribute
        # in ActiveRecord. For that to work properly, an instance of the correct AR-class needs
        # to be passed as context.
        def to_ar_name(attribute, context:, refer_to_ids: false)
          attribute = underscore_attribute attribute.to_s.underscore
          attribute = collapse_custom_field_name(attribute)

          special_conversion = special_api_to_ar_conversions[attribute]

          if refer_to_ids
            special_conversion = denormalize_foreign_key_name(special_conversion, context)
          end

          if special_conversion && context.respond_to?(special_conversion)
            special_conversion
          elsif refer_to_ids
            denormalize_foreign_key_name(attribute, context)
          else
            attribute
          end
        end

        private

        def special_api_to_ar_conversions
          @api_to_ar_conversions ||= Constants::ARToAPIConversions.all.inject({}) do |result, (k, v)|
            result[v.underscore] = k.to_s
            result
          end
        end

        # Unifies different attributes refering to the same thing via a foreign key
        # e.g. status_id -> status
        def normalize_foreign_key_name(attribute)
          attribute.to_s.sub(/(.+)_id\z/, '\1')
        end

        # Adds _id(s) suffix to field names that refer to foreign key relations,
        # leaves other names untouched.
        # e.g.
        #   status -> status_id
        #   watcher -> watcher_ids
        def denormalize_foreign_key_name(attribute, context)
          name, id_name = key_name_with_and_without_id attribute

          # When appending an ID is valid, the context object will understand that message
          # in case of a `belongs_to` relation (e.g. status => status_id). The second check is for
          # `has_many` relations (e.g. watcher => watcher_ids).
          if context.respond_to?(id_name)
            id_name
          elsif context.respond_to?(id_name.pluralize)
            id_name.pluralize
          else
            name
          end
        end

        def key_name_with_and_without_id(attribute_name)
          if attribute_name =~ /^(.*)_id$/
            [$1, attribute_name]
          else
            [attribute_name, "#{attribute_name}_id"]
          end
        end

        # expands short custom field column names to be represented in their long form
        # (e.g. cf_1 -> custom_field_1)
        def expand_custom_field_name(attribute)
          match = attribute.match /\Acf_(?<id>\d+)\z/

          if match
            "custom_field_#{match[:id]}"
          else
            attribute
          end
        end

        # collapses long custom field column names to be represented in their short form
        # (e.g. custom_field_1 -> cf_1)
        def collapse_custom_field_name(attribute)
          match = attribute.match /\Acustom_field_(?<id>\d+)\z/

          if match
            "cf_#{match[:id]}"
          else
            attribute
          end
        end

        def underscore_attribute(attribute)
          # vanilla underscore will not puts underscores between letters and digits
          # we add them with the power of regex (esp. used for custom fields)
          attribute.underscore.gsub(/([a-z])(\d)/, '\1_\2')
        end
      end
    end
  end
end
