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

class Projects::Settings::WorkPackages::InternalCommentsController < Projects::SettingsController
  menu_item :settings_work_packages

  def update
    enabled = ActiveRecord::Type::Boolean.new.cast(expected_params[:enabled_internal_comments])
    result = Projects::UpdateService
               .new(user: current_user, model: @project, contract_class: Projects::SettingsContract)
               .call(enabled_internal_comments: enabled)

    if result.success?
      flash[:notice] = t("notice_successful_update")
    else
      flash[:error] = t("notice_unsuccessful_update")
    end

    redirect_to project_settings_work_packages_internal_comments_path
  end

  private

  def expected_params
    params.expect(project: [:enabled_internal_comments])
  end
end
