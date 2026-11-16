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

module Webhooks
  class ManualScriptsController < ::ApplicationController
    include OpTurbo::ComponentStream

    layout false

    before_action :find_work_package
    before_action :authorize, except: :menu
    # The menu checks the permission itself and renders an empty frame without it.
    authorization_checked! :menu
    before_action :find_script, only: %i[new create]

    def menu
      allowed = current_user.allowed_in_work_package?(:run_manual_scripts, @work_package)
      @scripts = allowed ? ::Webhooks::KubernetesScript.manual_for(@work_package).to_a : []
      @frame_id = request.headers["Turbo-Frame"].presence || "wp-manual-scripts-menu"
    end

    def show
      runs = ::Webhooks::KubernetesScriptRun.trigger_manual.where(work_package: @work_package)
      runs = runs.where(triggered_by: current_user) unless current_user.admin?
      run = runs.find(params.expect(:id))
      return head(:no_content) if params[:reference] == run.status

      update_via_turbo_stream(
        component: ManualScripts::BodyComponent.new(script: run.kubernetes_script, work_package: @work_package, run:)
      )
      respond_with_turbo_streams
    end

    def new
      respond_with_dialog ManualScripts::DialogComponent.new(script: @script, work_package: @work_package)
    end

    def create
      schema = @script.form_schema
      raw = params.fetch(:input, {}).permit!.to_h
      input = schema.coerce(raw)
      errors = schema.validate(input)

      if errors.any?
        update_via_turbo_stream(
          component: ManualScripts::BodyComponent.new(script: @script, work_package: @work_package, values: raw, errors:),
          status: :unprocessable_entity
        )
      else
        run = start_run(input)
        update_via_turbo_stream(component: ManualScripts::BodyComponent.new(script: @script, work_package: @work_package, run:))
      end
      respond_with_turbo_streams
    end

    private

    def find_work_package
      @work_package = ::WorkPackage.visible.find(params.expect(:work_package_id))
      @project = @work_package.project
    end

    def find_script
      @script = ::Webhooks::KubernetesScript.manual_for(@work_package).find(params.expect(:script_id))
    end

    def start_run(input)
      run = ::Webhooks::KubernetesScriptRun.create!(
        kubernetes_script: @script,
        project: @project,
        work_package: @work_package,
        triggered_by: current_user,
        trigger: :manual,
        event_name: "work_package:manual",
        input:
      )
      ::KubernetesScriptJob.perform_later(run.id, ::WorkPackageWebhookJob.name, @work_package, actor: current_user)
      run
    end
  end
end
