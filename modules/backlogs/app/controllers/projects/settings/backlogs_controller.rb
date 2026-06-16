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

class Projects::Settings::BacklogsController < Projects::SettingsController
  menu_item :settings_backlogs

  def show; end

  def update
    call = Projects::UpdateService
      .new(model: @project,
           user: current_user,
           contract_class: ::Backlogs::Projects::BacklogsTypesAndStatusesContract)
      .call(backlogs_settings_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_back_or_to_backlogs_settings
    else
      flash.now[:error] = I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
      render action: :show, status: :unprocessable_entity
    end
  end

  def rebuild_positions
    ::Backlogs::WorkPackages::RebuildPositionsService.new(project: @project).call
    flash[:notice] = I18n.t("backlogs.positions_rebuilt_successfully")

    redirect_back_or_to_backlogs_settings
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = I18n.t("backlogs.positions_could_not_be_rebuilt")

    log_rebuild_position_error

    redirect_back_or_to_backlogs_settings
  end

  private

  def backlogs_settings_params
    permitted = params.expect(project: { done_status_ids: [], backlog_excluded_type_ids: [] })

    %i[done_status_ids backlog_excluded_type_ids].each do |key|
      # De-duplicate submitted values:
      permitted[key] = permitted[key]&.uniq
    end

    permitted
  end

  def redirect_back_or_to_backlogs_settings
    redirect_back_or_to project_settings_backlogs_path(@project)
  end

  def log_rebuild_position_error
    logger.error("Tried to rebuild positions for project #{@project.identifier.inspect} but could not...")
    logger.error($!)
    logger.error($@)
  end
end
