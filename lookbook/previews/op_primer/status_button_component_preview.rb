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

module OpPrimer
  # @logical_path OpenProject/Primer
  class StatusButtonComponentPreview < ViewComponent::Preview
    # See the [component documentation](/lookbook/pages/components/status_button) for more details.
    # @display min_height 100px
    # @param readonly [Boolean]
    # @param disabled [Boolean]
    # @param size [Symbol] select [small, medium, large]
    def playground(readonly: false, disabled: false, size: :medium)
      status = OpPrimer::StatusButtonOption.new(name: "Open",
                                                tag: :a,
                                                color_ref: :open,
                                                color_namespace: :meeting_status,
                                                href: "/some/test")
      items = [
        status,
        OpPrimer::StatusButtonOption.new(name: "Closed",
                                         tag: :a,
                                         color_ref: :closed,
                                         color_namespace: :meeting_status,
                                         href: "/some/other/action")
      ]
      component = OpPrimer::StatusButtonComponent.new(current_status: status,
                                                      items:,
                                                      readonly:,
                                                      disabled:,
                                                      button_arguments: {
                                                        title: "Edit",
                                                        size:
                                                      })

      render(component)
    end

    # See the [component documentation](/lookbook/pages/components/status_button) for more details.
    # @display min_height 100px
    def with_icon(size: :medium)
      status = OpPrimer::StatusButtonOption.new(name: "Open",
                                                color_ref: :open,
                                                color_namespace: :meeting_status,
                                                icon: :unlock)

      items = [
        status,
        OpPrimer::StatusButtonOption.new(name: "Closed",
                                         color_ref: :closed,
                                         color_namespace: :meeting_status,
                                         icon: :lock)
      ]

      component = OpPrimer::StatusButtonComponent.new(current_status: status,
                                                      items: items,
                                                      readonly: false,
                                                      button_arguments: { size:, title: "foo" })

      render(component)
    end

    # See the [component documentation](/lookbook/pages/components/status_button) for more details.
    # @display min_height 150px
    def with_description(size: :medium)
      status = OpPrimer::StatusButtonOption.new(name: "Open",
                                                color_ref: :open,
                                                color_namespace: :meeting_status,
                                                icon: :unlock,
                                                description: "The status is open")

      items = [
        status,
        OpPrimer::StatusButtonOption.new(name: "Closed",
                                         color_ref: :closed,
                                         color_namespace: :meeting_status,
                                         icon: :lock,
                                         description: "The status is closed")
      ]

      component = OpPrimer::StatusButtonComponent.new(current_status: status,
                                                      items: items,
                                                      readonly: false,
                                                      button_arguments: { size:, title: "foo" })

      render(component)
    end
  end
end
