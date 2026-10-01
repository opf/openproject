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

module Exports
  module Formatters
    module XLS
      class CustomField < ::Exports::Formatters::CustomField
        TYPED_FORMATS = %w[int float date calculated_value].freeze

        def self.apply?(attribute, export_format)
          export_format == :xls && attribute.start_with?("cf_")
        end

        def format_for_export(object, custom_field)
          return super unless typed?(custom_field)

          object.typed_custom_value_for(custom_field)
        end

        def format_value(value, options)
          return value if value.is_a?(Date) || value.is_a?(Numeric) || value.in?([true, false])

          super
        end

        def format_options
          return {} unless custom_field && typed?(custom_field)

          case custom_field.field_format
          when "date" then { number_format: DateFormat.date }
          when "int" then { number_format: integer_format }
          else { number_format: }
          end
        end

        private

        def typed?(custom_field)
          custom_field.field_format.in?(TYPED_FORMATS) && !custom_field.multi_value?
        end

        def custom_field
          return @custom_field if defined?(@custom_field)

          @custom_field = ::CustomField.find_by(id: attribute.to_s.delete_prefix("cf_"))
        end
      end
    end
  end
end
