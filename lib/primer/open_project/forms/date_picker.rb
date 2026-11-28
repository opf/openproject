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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class DatePicker < Primer::Forms::TextField
        def initialize(input:, datepicker_options:)
          super(input:)

          @field_wrap_arguments[:invalid] = true if @input.invalid?
          @datepicker_options = datepicker_options
        end

        private

        def picker_tag
          CustomElementHelper::TagBuilder
            .new(@view_context)
            .public_send(@datepicker_options.fetch(:component).underscore, **picker_attributes)
        end

        def picker_attributes
          {
            data: multi_input_data,
            **field_attributes,
            input_class_names: @datepicker_options.fetch(:class) { @input.input_arguments[:class] },
            input_attrs: inner_input_attributes.presence,
            placeholder: @input.input_arguments[:placeholder],
            in_dialog: @datepicker_options[:inDialog],
            show_clear_button: @datepicker_options[:showClearButton]
          }
        end

        def field_attributes
          {
            input_id: @datepicker_options.fetch(:id) { builder.field_id(@input.name) },
            name: @datepicker_options.fetch(:name) { builder.field_name(@input.name) },
            value: serialized_value
          }
        end

        def multi_input_data
          {
            targets: @input.input_arguments.dig(:data, :targets),
            name: @input.input_arguments.dig(:data, :name)
          }.compact
        end

        def serialized_value
          value = @datepicker_options.fetch(:value) { @input.input_arguments[:value] || builder.object&.send(@input.name) }
          value.respond_to?(:iso8601) ? value.iso8601 : value
        end

        # The action belongs on the inner input: on the custom element, Stimulus would bind it
        # a second time and run it again for the change event bubbling up from the input.
        def inner_input_attributes
          action = @datepicker_options.dig(:data, :action)

          { "data-action" => action }.compact.merge(@datepicker_options[:input_attributes] || {})
        end
      end
    end
  end
end
