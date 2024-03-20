#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Projects::TemplatedController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def create
    change_templated_action(true)
  end

  def destroy
    change_templated_action(false)
  end

  private

  def change_templated_action(templated)
    service_call = Projects::UpdateService
                     .new(user: current_user,
                          model: @project)
                     .call(templated:)

    if service_call.success?
      flash[:notice] = t(:notice_successful_update)
    else
      messages = [
        t('activerecord.errors.template.header', model: Project.model_name.human, count: service_call.errors.count),
        service_call.message
      ]

      flash[:error] = messages.join(". ")
    end

    redirect_to project_settings_general_path(@project)
  end
end
