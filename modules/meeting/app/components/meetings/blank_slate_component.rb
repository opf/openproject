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
  class BlankSlateComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper

    def initialize(project: nil, current_user: User.current, template: false)
      super

      @project = project
      @current_user = current_user
      @template = template
    end

    def can_create_meetings?
      if @project
        @current_user.allowed_in_project?(:create_meetings, @project)
      else
        @current_user.allowed_in_any_project?(:create_meetings)
      end
    end

    def new_one_time_meeting_path
      polymorphic_path([:new_dialog, @project, :meetings])
    end

    def new_recurring_meeting_path
      polymorphic_path([:new_dialog, @project, :meetings], type: :recurring)
    end

    def heading_text
      @template ? I18n.t("text_meeting_template_blank_slate_heading") : I18n.t("meeting.blankslate.title")
    end

    def description_text
      @template ? I18n.t("text_meeting_template_blank_slate") : I18n.t("meeting.blankslate.desc")
    end
  end
end
