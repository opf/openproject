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

module TimeEntries
  class UserForm < ApplicationForm
    include Redmine::I18n

    def initialize(visible: true)
      super()
      @visible = visible
    end

    form do |f|
      f.hidden name: :show_user, value: @visible

      if show_user_field?
        f.autocompleter(
          name: :user_id,
          id: "time_entry_user_id",
          label: TimeEntry.human_attribute_name(:user),
          caption: caption,
          required: true,
          autocomplete_options: {
            defaultData: true,
            hiddenFieldAction: "change->time-entry#userChanged",
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
            filters: user_completer_filters,
            searchKey: "any_name_attribute",
            resource: "principals",
            focusDirectly: false,
            multiple: false,
            clearable: false,
            appendTo: "#time-entry-dialog"
          }
        )
      end
    end

    private

    delegate :project, to: :model

    def show_user_field?
      return false unless @visible
      return false if project && !User.current.allowed_in_project?(:log_time, project)

      true
    end

    def user_completer_filters
      filters = [
        { name: "type", operator: "=", values: %w[User] },
        { name: "status", operator: "=", values: [Principal.statuses[:active], Principal.statuses[:invited]] }
      ]

      if model.project_id
        filters << { name: "member", operator: "=", values: [model.project_id] }
      end

      filters
    end

    def caption
      return if model.user.nil? || model.user.time_zone == User.current.time_zone

      I18n.t("notice_different_time_zones", tz: friendly_timezone_name(model.user.time_zone))
    end
  end
end
