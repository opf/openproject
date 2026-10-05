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

module API
  module V3
    module FieldRules
      module InputHelpers
        MAX_ID = 2_147_483_647
        MAX_LIST_SIZE = 1000
        TRUE_VALUES = [true, "true", "1", 1].freeze
        FALSE_VALUES = [false, "false", "0", 0, "", nil].freeze

        def safe_id(value)
          return 0 unless value.is_a?(String) || value.is_a?(Integer)

          value.to_s.to_i.clamp(0, MAX_ID)
        end

        def safe_bool(value)
          return true if TRUE_VALUES.include?(value)
          return false if FALSE_VALUES.include?(value)

          raise ::API::Errors::BadRequest.new("A boolean value is expected.")
        end

        def body_hash!
          body = request_body
          return {}.with_indifferent_access if body.nil?
          raise ::API::Errors::BadRequest.new("The request body must be a JSON object.") unless body.is_a?(Hash)

          body.with_indifferent_access
        end

        def text_attributes(body)
          %i[name description].each_with_object({}) do |key, attributes|
            next unless body.key?(key)
            raise ::API::Errors::BadRequest.new("#{key} must be a string.") unless body[key].nil? || body[key].is_a?(String)

            attributes[key] = body[key]
          end
        end

        def safe_string(value)
          value.is_a?(String) || value.is_a?(Numeric) ? value.to_s : nil
        end

        def id_from_link(item, key, namespace)
          link = item.dig(:_links, key)
          href = link.is_a?(Hash) ? link[:href] : nil
          return if href.blank?

          ::API::Utilities::ResourceLinkParser.parse_id(href, property: key.to_s, expected_version: "3",
                                                              expected_namespace: namespace)
        end

        def raise_service_errors(result)
          raise ::API::Errors::ErrorBase.create_and_merge_errors(result.errors)
        end

        def objects_array!(value, name)
          return value if value.is_a?(Array) && value.size <= MAX_LIST_SIZE && value.all?(Hash)

          raise ::API::Errors::BadRequest.new("#{name} must be a list of at most #{MAX_LIST_SIZE} objects.")
        end
      end
    end
  end
end
