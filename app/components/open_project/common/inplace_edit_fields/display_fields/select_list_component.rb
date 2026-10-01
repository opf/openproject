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

module OpenProject
  module Common
    module InplaceEditFields
      module DisplayFields
        class SelectListComponent < DisplayFieldComponent
          include CustomFieldsHelper

          attr_reader :model, :attribute, :writable

          def render_display_value
            value = model.public_send(attribute)

            if value.present? && value != [nil]
              render_value(value)
            else
              t("placeholders.default")
            end
          end

          private

          def render_value(value)
            if custom_field?
              formatted_custom_field_values.presence || t("placeholders.default")
            else
              value.is_a?(Array) ? value.join(", ") : value.to_s
            end
          end

          def formatted_custom_field_values
            return @formatted_custom_field_values if defined?(@formatted_custom_field_values)

            values = custom_field_values.map { |v| format_value(v.value, custom_field) }

            @formatted_custom_field_values = custom_field&.multi_value? ? values.join(", ") : values.first
          end
        end
      end
    end
  end
end
