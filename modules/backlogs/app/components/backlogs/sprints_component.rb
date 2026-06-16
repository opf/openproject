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

module Backlogs
  class SprintsComponent < ApplicationComponent
    include Primer::AttributesHelper
    include CommonHelper

    attr_reader :sprints, :work_packages_by_sprint_id, :active_sprint_ids, :project, :current_user

    def initialize(sprints:,
                   work_packages_by_sprint_id:,
                   active_sprint_ids:,
                   project:,
                   current_user: User.current)
      super()

      @sprints = sprints
      @work_packages_by_sprint_id = work_packages_by_sprint_id
      @active_sprint_ids = active_sprint_ids
      @project = project
      @current_user = current_user
    end

    private

    def blankslate_description
      if sprint_management_allowed?
        description_with_settings_link
      else
        description
      end
    end

    def description_with_settings_link
      settings_link = link_to(
        t(".blankslate.settings_link_text"),
        project_settings_backlog_sharing_path(project)
      )

      if project.receive_shared_sprints?
        t(".blankslate.receive_and_manage_description_html", settings_link:)
      elsif sprint_creation_allowed?
        t(".blankslate.create_and_manage_description_html", settings_link:)
      else
        t(".blankslate.manage_description_html", settings_link:)
      end
    end

    def description
      if project.receive_shared_sprints?
        t(".blankslate.receive_description_text")
      elsif sprint_creation_allowed?
        t(".blankslate.create_description_text")
      else
        t(".blankslate.no_actions_description_text")
      end
    end
  end
end
