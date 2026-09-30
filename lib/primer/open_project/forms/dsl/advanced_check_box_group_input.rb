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
        class AdvancedCheckBoxGroupInput < Primer::Forms::Dsl::Input
          attr_reader :name, :label, :check_boxes

          def initialize(name: nil, label: nil, **system_arguments)
            @name = name
            @label = label
            @check_boxes = []

            super(**system_arguments)

            yield(self) if block_given?
          end

          def to_component
            AdvancedCheckBoxGroup.new(input: self)
          end

          def type
            :check_box_group
          end

          def focusable?
            true
          end

          def autofocus!
            @check_boxes.first&.autofocus!
          end

          def check_box(**system_arguments, &)
            args = {
              name: @name,
              builder: @builder,
              form: @form,
              scheme: scheme,
              disabled: disabled?,
              **system_arguments
            }

            @check_boxes << AdvancedCheckBoxInput.new(**args, &)
          end

          private

          def scheme
            @name ? :array : :boolean
          end
        end
      end
    end
  end
end
