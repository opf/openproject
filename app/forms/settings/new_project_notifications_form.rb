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

module Settings
  class NewProjectNotificationsForm < ApplicationForm
    settings_form do |f|
      f.check_box(
        name: :new_project_send_confirmation_email,
        label: I18n.t(:setting_new_project_send_confirmation_email),
        data: {
          "show-when-checked-target": "cause",
          target_name: "send_confirmation_email"
        }
      )

      f.rich_text_area(
        name: :new_project_notification_text,
        value: Setting.new_project_notification_text.presence ||
               I18n.t("admin.settings.new_project.notification_text_default"),
        required: true,
        rich_text_options: {
          showAttachments: false,
          editorType: "constrained"
        },
        wrapper_classes: Setting.new_project_send_confirmation_email ? "" : "d-none",
        wrapper_data_attributes: {
          "show-when-checked-target": "effect",
          target_name: "send_confirmation_email",
          "visibility-class": "d-none"
        }
      )

      f.submit
    end
  end
end
