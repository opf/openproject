#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs::Hooks
  class WorkPackagesOverviewHook < Redmine::Hook::ViewListener

    def work_packages_overview_attributes(context = {})
      project = context[:project]
      attributes = context[:attributes]

      return unless project && project.module_enabled?(:costs_module)

      attributes.reject!{ |attribute| attribute == :spentTime }

      attributes << :costObject
      attributes << :spentHours if user_allowed_to?(project, :view_time_entries, :view_own_time_entries)
      attributes << :overallCosts
      attributes << :spentUnits if user_allowed_to?(project, :view_cost_entries, :view_own_cost_entries)

      attributes
    end

    private

    def user_allowed_to?(project, *privileges)
      privileges.inject(false) do |result, privilege|
        result || User.current.allowed_to?(privilege, project)
      end
    end
  end
end
