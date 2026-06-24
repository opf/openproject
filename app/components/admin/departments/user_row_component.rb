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

module Admin
  module Departments
    class UserRowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      def initialize(user:, group:)
        super()
        @user = user
        @group = group
      end

      def call
        flex_layout(align_items: :center, justify_content: :space_between) do |row|
          row.with_column do
            render(Users::AvatarComponent.new(user: @user, size: "mini"))
          end

          unless @group&.ldap_managed?
            row.with_column do
              render(Primer::Alpha::ActionMenu.new) do |menu|
                menu.with_show_button(
                  icon: "kebab-horizontal",
                  scheme: :invisible,
                  "aria-label": I18n.t(:label_actions)
                )
                menu.with_item(
                  label: I18n.t(:button_remove),
                  scheme: :danger,
                  tag: :a,
                  href: remove_user_admin_department_path(@group, @user.id),
                  content_arguments: {
                    data: {
                      turbo_confirm: I18n.t(:text_are_you_sure),
                      turbo_method: :delete,
                      turbo_frame: "_top"
                    }
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
