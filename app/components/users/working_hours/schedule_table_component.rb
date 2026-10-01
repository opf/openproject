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

module Users
  module WorkingHours
    class ScheduleTableComponent < OpPrimer::BorderBoxTableComponent
      columns :start_date, :work_days, :work_hours, :availability_factor, :effective_work_hours
      main_column :work_days

      attr_reader :variant, :user

      def initialize(rows:, variant:, user:, **)
        super(rows:, **)
        @variant = variant
        @user = user
      end

      def has_actions?
        true
      end

      def blank_icon
        :calendar
      end

      def row_class
        Users::WorkingHours::ScheduleRowComponent
      end

      def mobile_title
        I18n.t("users.working_hours.table.mobile_title")
      end

      def headers
        [
          [:start_date, { caption: I18n.t("users.working_hours.table.start_date") }],
          [:work_days, { caption: I18n.t("users.working_hours.table.work_days") }],
          [:work_hours, { caption: I18n.t("users.working_hours.table.work_hours") }],
          [:availability_factor, { caption: I18n.t("users.working_hours.table.availability_factor") }],
          [:effective_work_hours, { caption: I18n.t("users.working_hours.table.effective_work_hours") }]
        ]
      end

      def action_row_header_content
        return unless variant == :future
        return unless UserWorkingHours::CreateContract.can_create?(user: User.current, target_user: user)

        render(Primer::Beta::IconButton.new(
                 icon: :plus,
                 scheme: :invisible,
                 tag: :a,
                 href: new_user_working_hour_path(user),
                 data: { turbo: true, controller: "async-dialog" },
                 "aria-label": I18n.t("users.working_hours.future.add_button")
               ))
      end

      def blank_title
        I18n.t("users.working_hours.#{@variant}.blank_title")
      end

      def blank_description
        I18n.t("users.working_hours.#{@variant}.blank_description")
      end

      def render_blank_slate
        render(Primer::Beta::Blankslate.new(border: false)) do |component|
          component.with_visual_icon(icon: :calendar, size: :medium)
          component.with_heading(tag: :h2) { blank_title }
          component.with_description { blank_description }
          if variant == :future && UserWorkingHours::CreateContract.can_create?(user: User.current, target_user: user)
            component.with_primary_action(href: new_user_working_hour_path(user),
                                          data: { turbo: true,
                                                  controller: "async-dialog" }) do
              I18n.t("users.working_hours.future.add_button")
            end
          end
        end
      end
    end
  end
end
