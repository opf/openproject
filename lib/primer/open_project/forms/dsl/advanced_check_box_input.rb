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
        class AdvancedCheckBoxInput < Primer::Forms::Dsl::Input
          DEFAULT_SCHEME = :boolean
          SCHEMES = [DEFAULT_SCHEME, :array].freeze

          attr_reader :name, :label, :value, :unchecked_value, :scheme, :leading_icon, :trailing_image

          # @param leading_icon [Symbol] octicon shown before the label.
          # @param trailing_image [String] path to an SVG shown at the far end of the card.
          def initialize(name:, label:, value: nil, unchecked_value: nil, scheme: DEFAULT_SCHEME,
                         leading_icon: nil, trailing_image: nil, **system_arguments)
            raise ArgumentError, "Check box scheme must be one of #{SCHEMES.join(', ')}" unless SCHEMES.include?(scheme)

            raise ArgumentError, "Check box needs an explicit value if scheme is array" if scheme == :array && value.nil?

            @name = name
            @label = label
            @value = value
            @unchecked_value = unchecked_value
            @scheme = scheme
            @leading_icon = leading_icon
            @trailing_image = trailing_image

            super(**system_arguments)

            yield(self) if block_given?
          end

          # check boxes cannot be invalid, as both checked and unchecked are valid states
          # :nocov:
          def valid?
            true
          end
          # :nocov:

          def to_component
            AdvancedCheckBox.new(input: self)
          end

          def type
            :check_box
          end

          def supports_validation?
            false
          end

          def values_disambiguate_template_names?
            # Check boxes submitted as an array all have the same name, so we return true here
            # to ensure different caption templates can be attached to individual check box inputs.
            @scheme == :array
          end
        end
      end
    end
  end
end
