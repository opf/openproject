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
        class SegmentedControlInput < Primer::Forms::Dsl::Input
          Item = Data.define(:value, :label)

          attr_reader :name, :label, :current_value, :items, :wrapper_data_attributes

          def initialize(name:, label:, value:, items:, wrapper_data_attributes: {}, **system_arguments)
            @name = name
            @label = label
            @items = items.map { |item| Item.new(value: item[:value], label: item[:label]) }
            @current_value = value.presence || @items.first&.value
            @wrapper_data_attributes = wrapper_data_attributes

            super(**system_arguments)
          end

          def to_component
            SegmentedControl.new(input: self)
          end

          def type
            :segmented_control
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
