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

module Planner
  # Deletes a user's "My work" project once its last member is gone, as when the user is deleted, so
  # their to-dos are not left behind.
  class OrphanedProjectService
    def initialize(member)
      @member = member
    end

    def call
      return ServiceResult.success unless orphaned_planner_project?

      Projects::ScheduleDeletionService.new(user: User.system, model: project).call
    end

    private

    attr_reader :member

    delegate :project, :principal, to: :member, private: true

    def orphaned_planner_project?
      principal.is_a?(User) && project && principal.pref.planner_project_id == project.id && project.members.none?
    end
  end
end
