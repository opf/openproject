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
  # Base class of all controllers in Backlogs
  class BaseController < ::ApplicationController
    include Backlogs::CommonHelper

    helper "backlogs/common"

    before_action :load_project,
                  :load_sprint,
                  :authorize

    private

    # Loads the project to be used by the authorize filter to determine if
    # User.current has permission to invoke the method in question.
    def load_project
      @project = Project.visible.find(params.expect(:project_id))
    end

    def load_sprint
      @sprint_id = params[:sprint_id].presence
      return unless @sprint_id

      @sprint = Sprint.for_project(@project).visible.find(@sprint_id)
    end
  end
end
