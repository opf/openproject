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
  class SprintFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include CommonHelper

    FORM_ID = SprintDialogComponent::FORM_ID

    attr_reader :sprint, :base_errors

    def initialize(sprint:, base_errors: nil)
      super

      @sprint = sprint
      @base_errors = base_errors
    end

    private

    def http_verb
      sprint.new_record? ? :post : :put
    end

    def form_url
      if sprint.new_record?
        project_backlogs_sprints_path(sprint.project_id, all_backlogs_params)
      else
        project_backlogs_sprint_path(sprint.project_id, sprint.id, all_backlogs_params)
      end
    end

    def data_attributes
      {
        controller: "refresh-on-form-changes",
        "refresh-on-form-changes-target": "form",
        "refresh-on-form-changes-turbo-stream-url-value": refresh_form_project_backlogs_sprints_path(sprint.project_id,
                                                                                                     all_backlogs_params)
      }
    end
  end
end
