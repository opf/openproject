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

module Grids
  class DashboardPage < Grid
    belongs_to :project, optional: true
    has_many :dashboard_page_assignments, foreign_key: :grid_id, inverse_of: :dashboard, dependent: :delete_all

    validates :name, presence: true, length: { maximum: 255 }

    set_acts_as_attachable_options skip_permission_checks: false,
                                   view_permission: :view_project,
                                   add_permission: :manage_dashboards,
                                   delete_permission: :manage_dashboards

    scope :central, -> { where(project_id: nil) }
    scope :in_project, ->(project) {
      where(project:).or(central.where(id: DashboardPageAssignment.where(project:).select(:grid_id)))
    }
    scope :active_in, ->(project) {
      where(project:, disabled: false)
        .or(central.where(id: DashboardPageAssignment.where(project:, active: true).select(:grid_id)))
    }

    def grid_scope_path
      helpers = OpenProject::StaticRouting::StaticUrlHelpers.new
      if central?
        helpers.edit_admin_dashboard_page_path(self)
      else
        helpers.project_dashboard_page_path(project, self)
      end
    end

    def central?
      project_id.nil?
    end

    def set_active_in!(project, active:)
      if central?
        dashboard_page_assignments.find_by!(project:).update!(active:)
      else
        raise ActiveRecord::RecordNotFound unless project.id == project_id

        update!(disabled: !active)
      end
    end

    private

    def allowed_to_on_attachment?(user, permissions)
      return !disabled? && super unless central?
      return true if user.allowed_globally?(:manage_standard_dashboards)
      return false unless permissions == :view_project

      dashboard_page_assignments.exists?(active: true, project: Project.visible(user))
    end
  end
end
