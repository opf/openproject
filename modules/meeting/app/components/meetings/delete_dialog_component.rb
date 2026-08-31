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

module Meetings
  class DeleteDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(meeting:, back_url: nil)
      super

      @meeting = meeting
      @project = meeting.project
      @back_url = back_url
    end

    delegate :recurring_meeting, to: :@meeting

    private

    def id = "delete-meeting-dialog"

    def title
      if recurring_meeting.present?
        I18n.t("meeting.delete_dialog.#{occurrence_key}.title")
      else
        template = @meeting.onetime_template? ? ".template" : ""
        I18n.t("meeting.delete_dialog.one_time#{template}.title")
      end
    end

    def heading
      if recurring_meeting.present?
        I18n.t("meeting.delete_dialog.#{occurrence_key}.heading")
      else
        template = @meeting.onetime_template? ? ".template" : ""
        I18n.t("meeting.delete_dialog.one_time#{template}.heading")
      end
    end

    def confirmation_message
      if recurring_meeting.present?
        t("meeting.delete_dialog.#{occurrence_key}.confirmation_message_html")
      else
        template = @meeting.onetime_template? ? ".template" : ""
        t("meeting.delete_dialog.one_time#{template}.confirmation_message_html")
      end
    end

    def confirm_button_text
      if recurring_meeting.present?
        I18n.t("meeting.delete_dialog.#{occurrence_key}.confirm_button")
      else
        I18n.t("button_delete")
      end
    end

    def cancel_button_text
      if recurring_meeting.present?
        I18n.t("button_close")
      else
        I18n.t("button_cancel")
      end
    end

    def occurrence_key
      @meeting.past? ? "occurrence_past" : "occurrence"
    end
  end
end
