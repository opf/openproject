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

class Projects::Settings::BacklogsController < Projects::SettingsController
  menu_item :settings_backlogs

  def show
    @statuses_done_for_project = @project.done_statuses.select(:id).map(&:id)
  end

  def update
    selected_statuses = (params[:statuses] || []).filter_map do |work_package_status|
      Status.find(work_package_status[:status_id].to_i)
    end

    @project.done_statuses = selected_statuses
    @project.save!

    flash[:notice] = I18n.t(:notice_successful_update)

    redirect_to_backlogs_settings
  end

  def rebuild_positions
    @project.rebuild_positions
    flash[:notice] = I18n.t("backlogs.positions_rebuilt_successfully")

    redirect_to_backlogs_settings
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = I18n.t("backlogs.positions_could_not_be_rebuilt")

    log_rebuild_position_error

    redirect_to_backlogs_settings
  end

  private

  def redirect_to_backlogs_settings
    redirect_to project_settings_backlogs_path(@project)
  end

  def log_rebuild_position_error
    logger.error("Tried to rebuild positions for project #{@project.identifier.inspect} but could not...")
    logger.error($!)
    logger.error($@)
  end
end
