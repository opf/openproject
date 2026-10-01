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

module MeetingTemplates
  class IndexSubHeaderComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(project: nil)
      super
      @project = project
    end

    def render_create_button?
      return false unless EnterpriseToken.allows_to?(:meeting_templates)

      if @project
        User.current.allowed_in_project?(:create_meetings, @project)
      else
        User.current.allowed_in_any_project?(:create_meetings)
      end
    end

    def create_path
      if @project
        create_template_project_meetings_path(@project)
      else
        new_dialog_template_meetings_path
      end
    end

    def use_dialog?
      @project.nil?
    end

    def button_data
      use_dialog? ? { controller: "async-dialog" } : { turbo_method: :post }
    end

    def id
      "add-template-button"
    end

    def accessibility_label_text
      I18n.t(:label_meeting_template_new)
    end

    def label_text
      I18n.t(:label_template)
    end
  end
end
