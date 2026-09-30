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
        # :nodoc:
        class AdvancedRadioButtonGroupInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :radio_buttons

          def initialize(name:, label: nil, **system_arguments)
            @name = name
            @label = label
            @radio_buttons = []

            super(**system_arguments)

            yield(self) if block_given?
          end

          def to_component
            AdvancedRadioButtonGroup.new(input: self)
          end

          def type
            :radio_button_group
          end

          def autofocus!
            @radio_buttons.first&.autofocus!
          end

          def focusable?
            true
          end

          def radio_button(**system_arguments, &)
            @radio_buttons << AdvancedRadioButtonInput.new(
              builder: @builder, form: @form, name: @name, disabled: disabled?,
              **system_arguments, &
            )
          end
        end
      end
    end
  end
end
