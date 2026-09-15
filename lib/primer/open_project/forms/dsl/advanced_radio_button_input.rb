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

module Primer
  module OpenProject
    module Forms
      module Dsl
        # :nodoc:
        class AdvancedRadioButtonInput < Primer::Forms::Dsl::Input
          attr_reader :name, :value, :label, :leading_icon, :trailing_image, :title_link, :action

          def initialize(name:, value:, label:, leading_icon: nil, trailing_image: nil, title_link: nil, action: nil,
                         **system_arguments)
            @name = name
            @value = value
            @label = label
            @leading_icon = leading_icon
            @trailing_image = trailing_image
            @title_link = title_link
            @action = action

            super(**system_arguments)

            yield(self) if block_given?
          end

          def checked?
            !!input_arguments[:checked]
          end

          def title_link_text = title_link&.dig(:text)

          def title_link_arguments = title_link&.except(:text) || {}

          def action_text = action&.dig(:text)

          def action_arguments = action&.except(:text) || {}

          # radio buttons cannot be invalid, as both selected and unselected are valid states
          # :nocov:
          def valid?
            true
          end
          # :nocov:

          def to_component
            AdvancedRadioButton.new(input: self)
          end

          # :nocov:
          def type
            :radio_button
          end
          # :nocov:

          def supports_validation?
            false
          end

          def values_disambiguate_template_names?
            true
          end
        end
      end
    end
  end
end
