#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_dependency 'projects_controller'

module OpenProject::Backlogs::Patches::ProjectsControllerPatch
  def self.included(base)
    base.class_eval do
      prepend InstanceMethods
    end
  end

  module InstanceMethods
    def project_done_statuses
      selected_statuses = (params[:statuses] || []).map { |work_package_status|
        Status.find(work_package_status[:status_id].to_i)
      }.compact

      @project.done_statuses = selected_statuses
      @project.save!

      flash[:notice] = l(:notice_successful_update)

      redirect_to_backlogs_settings
    end

    def rebuild_positions
      @project.rebuild_positions
      flash[:notice] = l('backlogs.positions_rebuilt_successfully')

      redirect_to_backlogs_settings
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = l('backlogs.positions_could_not_be_rebuilt')

      logger.error("Tried to rebuild positions for project #{@project.identifier.inspect} but could not...")
      logger.error($!)
      logger.error($@)

      redirect_to_backlogs_settings
    end

    def redirect_to_backlogs_settings
      redirect_to controller: 'backlogs_settings', action: 'show', id: @project
    end
  end
end

ProjectsController.send(:include, OpenProject::Backlogs::Patches::ProjectsControllerPatch)
