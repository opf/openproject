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
      module Dsl
        class AutocompleterInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :autocomplete_options, :select_options, :wrapper_data_attributes, :wrapper_classes

          class Option
            attr_reader :label, :value, :selected, :classes, :group_by, :disabled

            def initialize(label:, value:, classes: nil, selected: false, group_by: nil, disabled: false)
              @label = label
              @value = value
              @selected = selected
              @classes = classes
              @group_by = group_by
              @disabled = disabled
            end

            def to_h
              { id: value, name: label }.merge({ selected:, disabled:, group_by:, classes: }.compact)
            end
          end

          def initialize(name:, label:, autocomplete_options:, wrapper_data_attributes: {}, wrapper_classes: [],
                         **system_arguments)
            @name = name
            @label = label
            @autocomplete_options = derive_autocompleter_options(autocomplete_options)
            @wrapper_data_attributes = wrapper_data_attributes
            @wrapper_classes = wrapper_classes
            @select_options = []

            super(**system_arguments)

            yield(self) if block_given?
          end

          def derive_autocompleter_options(options)
            options.reverse_merge(
              component: "opce-autocompleter"
            )
          end

          def option(**args)
            @select_options << Option.new(**args)
          end

          def to_component
            Autocompleter.new(input: self, autocomplete_options:, wrapper_data_attributes:, wrapper_classes:)
          end

          def type
            :autocompleter
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
