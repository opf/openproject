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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module Patterns
    class TokenPropertyMapper
      STRING_OR_NIL = ->(v, _) { v&.to_s }
      ARRAY = ->(v, _) { v.compact.presence&.join(", ") }
      DATE = ->(v, _) { v&.strftime(Setting.date_format || "%Y-%m-%d") }
      DURATION = ->(v, _) { DurationConverter.output(v) }

      class << self
        def add_static_attribute(key, context, label_fn, value_fn, formatter = STRING_OR_NIL)
          static_tokens << AttributeToken.new(key, context, label_fn, value_fn, formatter)
        end

        def static_tokens
          @static_tokens ||= []
        end

        def add_custom_fields(scope_fn, context, prefix = "")
          custom_field_definitions << [scope_fn, context, prefix]
        end

        def custom_field_definitions
          @custom_field_definitions ||= []
        end
      end

      def partitioned_tokens_for_type(variant)
        enabled_cf_tokens = custom_field_tokens(variant)
        [self.class.static_tokens + enabled_cf_tokens, custom_field_tokens(nil) - enabled_cf_tokens]
      end

      private

      def custom_field_tokens(variant)
        self.class.custom_field_definitions.flat_map do |scope_fn, context, prefix|
          tokenize(scope_fn.call(variant), context, prefix)
        end
      end

      def tokenize(custom_field_scope, context_name, prefix = nil)
        custom_field_scope.pluck(:name, :id, :field_format, :multi_value).map do |name, id, format, multiple|
          formatter = if multiple
                        ARRAY
                      elsif format == "date"
                        DATE
                      else
                        ->(v, format) { v.is_a?(Symbol) ? v : STRING_OR_NIL.call(v, format) }
                      end
          AttributeToken.new(
            :"#{prefix}custom_field_#{id}",
            context_name,
            -> { name },
            ->(context) do
              key = :"custom_field_#{id}"
              return :attribute_not_available unless context.respond_to?(key)

              context.public_send(key)
            end,
            formatter
          )
        end
      end
    end
  end
end
