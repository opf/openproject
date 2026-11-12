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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SubmenuComponentPreview < Lookbook::Preview
      # @label Default
      # @display min_height 450px
      def default
        render_with_template(template: "open_project/common/submenu_preview/default")
      end

      # @label Playground
      # @display min_height 450px
      # @param searchable [Boolean]
      # @param with_create_button [Boolean]
      # @param favorited [Boolean]
      # @param count [Integer]
      # @param show_enterprise_icon [Boolean]
      # @param icon [Symbol] octicon
      def playground(searchable: false,
                     with_create_button: false,
                     favorited: false,
                     count: nil,
                     show_enterprise_icon: false,
                     icon: nil)
        render_with_template(template: "open_project/common/submenu_preview/playground",
                             locals: {
                               searchable:,
                               create_btn_options: with_create_button ? { href: "/#", module_key: "user" } : nil,
                               favorited:,
                               count:,
                               show_enterprise_icon:,
                               icon:
                             })
      end
    end
  end
end
