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
#
module OpenProject
  module Common
    class CheckAllComponent < ApplicationComponent
      include Primer::AttributesHelper

      attr_reader :checkable_id, :base_id

      CHECKABLE_CONTROLLER_SELECTOR = "[data-controller~='checkable']"

      renders_one :separator

      renders_one :check_all_button, ->(**system_arguments) {
        action = use_outlet? ? "check-all#checkAll:stop" : "checkable#checkAll:stop"
        controls = checkable_id if use_outlet?

        system_arguments[:scheme] ||= :link
        system_arguments[:id] = "#{base_id}-check-all"
        system_arguments[:data] = merge_data(
          system_arguments, {
            data: { action: }
          }
        )
        system_arguments[:aria] = merge_aria(
          system_arguments, { aria: { controls: } }
        )

        Primer::Beta::Button.new(**system_arguments)
      }

      renders_one :uncheck_all_button, ->(**system_arguments) {
        action = use_outlet? ? "check-all#uncheckAll:stop" : "checkable#uncheckAll:stop"
        controls = checkable_id if use_outlet?

        system_arguments[:scheme] ||= :link
        system_arguments[:id] = "#{base_id}-uncheck-all"
        system_arguments[:data] = merge_data(
          system_arguments, {
            data: { action: }
          }
        )
        system_arguments[:aria] = merge_aria(
          system_arguments, { aria: { controls: } }
        )

        Primer::Beta::Button.new(**system_arguments)
      }

      # This Component can be used in *two* ways.
      #
      # 1. without passing `checkable_id`: this component should be rendered
      # within (as a descendant of) an element with a connected `checkable`
      # Stimulus controller.
      #
      # 2. passing `checkable_id`: this component can be rendered anywhere on the
      # page. This component takes care of connecting a `check-all` Stimulus
      # controller. The `check-all` controller uses OUTLETS to communicate with
      # the referenced `checkable` controller.
      #
      # In both cases, the implementer is responsible for connecting the
      # `checkable` controller.
      #
      # @param checkable_id [String] An id for the ancestor of an HTMLElement
      #   with connected `checkable` controller.
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(checkable_id: nil, **system_arguments)
        super()

        @checkable_id = checkable_id
        @base_id = checkable_id || self.class.generate_id

        @system_arguments = system_arguments
        @system_arguments[:tag] ||= :span
        if use_outlet?
          @system_arguments[:data] = merge_data(
            @system_arguments, {
              data: {
                controller: "check-all",
                check_all_checkable_outlet: "##{checkable_id} #{CHECKABLE_CONTROLLER_SELECTOR}"
              }
            }
          )
        end
      end

      private

      def use_outlet?
        @checkable_id.present?
      end
    end
  end
end
