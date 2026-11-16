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

class Projects::Settings::KubernetesScriptsController < Projects::SettingsController
  menu_item :settings_kubernetes_scripts

  def show
    @scripts = ::Webhooks::KubernetesScript.includes(:kubernetes_connection).order(:name)
    @enabled_ids = ::Webhooks::KubernetesProjectScript.where(project: @project).pluck(:kubernetes_script_id)
    @runs = ::Webhooks::KubernetesScriptRun
      .where(project: @project)
      .includes(:kubernetes_script, :triggered_by)
      .order(id: :desc)
      .limit(20)
  end

  def update
    ids = ::Webhooks::KubernetesScript.where(id: params.fetch(:script_ids, [])).pluck(:id)

    ::Webhooks::KubernetesProjectScript.transaction do
      ::Webhooks::KubernetesProjectScript.where(project: @project).where.not(kubernetes_script_id: ids).destroy_all
      existing = ::Webhooks::KubernetesProjectScript.where(project: @project).pluck(:kubernetes_script_id)
      (ids - existing).each do |id|
        ::Webhooks::KubernetesProjectScript.create!(project: @project, kubernetes_script_id: id)
      end
    end

    flash[:notice] = I18n.t(:notice_successful_update)
    redirect_to project_settings_kubernetes_scripts_path(@project), status: :see_other
  end
end
