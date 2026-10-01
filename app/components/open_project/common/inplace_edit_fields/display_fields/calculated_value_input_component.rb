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
        class CalculatedValueInputComponent < DisplayFieldComponent
          include OpPrimer::ComponentHelpers
          include CalculatedValues::ErrorsHelper

          attr_reader :model, :attribute

          # If the writable attribute is not explicitly listed as an argument,
          # it will be interpreted as one of the system_arguments and thus overwrite the `writable: false`
          # rubocop:disable Lint/UnusedMethodArgument
          def initialize(model:, attribute:, writable: nil, truncated: false, has_comment: false, show_comment: false,
                         **system_arguments)
            super(model:, attribute:, writable: false, truncated:, has_comment:, show_comment:, **system_arguments)
          end
          # rubocop:enable Lint/UnusedMethodArgument

          def render_calculation_error
            error = custom_field&.first_calculation_error(model)
            return unless error

            render(Primer::OpenProject::FlexLayout.new(
                     align_items: :flex_start,
                     data: { test_selector: "error--custom_field_#{custom_field.id}" }
                   )) do |container|
              container.with_column do
                render Primer::Beta::Octicon.new(icon: :"alert-fill", color: :danger)
              end
              container.with_column(ml: 2) do
                render Primer::Beta::Text.new(color: :danger) do
                  calculated_value_error_msg(error)
                end
              end
            end
          end

          def render_tooltip
            render Primer::Alpha::Tooltip.new(
              for_id: @system_arguments[:id],
              type: :description,
              text: I18n.t("custom_fields.calculated_field_not_editable"),
              direction: :s
            )
          end
        end
      end
    end
  end
end
