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

module MeetingAgendaItems
  class ListComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, form_hidden: true, form_type: :simple)
      super

      @meeting = meeting
      @form_hidden = form_hidden
      @form_type = form_type
    end

    def empty?
      @meeting.agenda_items.reject { |item| item.meeting_section&.backlog? }.empty? && @meeting.sections.empty?
    end

    private

    def drop_target_config
      {
        meetings__drag_and_drop_target: "container",
        "target-allowed-drag-type": "section" # the type of dragged items which are allowed to be dropped in this target
      }
    end

    def insert_target_modified?
      true
    end

    def insert_target_modifier_id
      "meeting-section-new-item"
    end

    def sections_except_backlog
      @meeting.sections.reject { |s| s.backlog? || !s.persisted? }
    end

    def banner
      render Primer::Alpha::Banner.new(
        scheme: :default,
        icon: :info,
        dismiss_scheme: :none
      ) do
        if @meeting.series_template?
          draft = @meeting.draft? ? "draft_" : ""
          t(
            "recurring_meeting.template.#{draft}banner_html",
            link: link_to(
              @meeting.recurring_meeting.title,
              project_recurring_meeting_path(@meeting.project, @meeting.recurring_meeting)
            )
          )
        elsif @meeting.onetime_template?
          t("text_onetime_meeting_template_banner")
        elsif @meeting.draft?
          t("text_meeting_draft_banner")
        end
      end
    end
  end
end
