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

module Meetings
  class SidePanel::ToggleNotificationsDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(meeting)
      super

      @meeting = meeting
      @project = meeting.project
    end

    private

    def id = "toggle-notifications-dialog"

    def title
      if @meeting.notify?
        I18n.t("meeting.notifications.dialog.title.disable")
      else
        I18n.t("meeting.notifications.dialog.title.enable")
      end
    end

    def confirmation_message
      if @meeting.notify?
        I18n.t("meeting.notifications.dialog.message.disable")
      else
        I18n.t("meeting.notifications.dialog.message.enable")
      end
    end

    def confirm_button_text
      if @meeting.notify?
        I18n.t("meeting.notifications.dialog.confirm_label.disable")
      else
        I18n.t("meeting.notifications.dialog.confirm_label.enable")
      end
    end

    def cancel_button_text
      I18n.t("button_cancel")
    end
  end
end
