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

module Messages
  class WorkPackagesController < ApplicationController
    include OpTurbo::ComponentStream

    layout false

    before_action :find_message
    authorize_with_permission :add_work_packages

    def new
      respond_with_dialog WorkPackages::Dialogs::CreateDialogComponent.new(
        work_package: service.build_work_package,
        project: @project,
        keep_open_on_success: false,
        **form_urls
      )
    end

    def refresh_form
      update_via_turbo_stream(component: form_component(service.build_work_package(params: permitted_params.update_work_package)))

      respond_with_turbo_streams
    end

    def create
      call = service.call(work_package_params: permitted_params.update_work_package)

      if call.success?
        flash[:notice] = created_flash(call.result)
        redirect_to helpers.message_anchor_path(@message), status: :see_other
      else
        update_via_turbo_stream(component: form_component(call.result), status: :bad_request)

        respond_with_turbo_streams
      end
    end

    private

    def find_message
      @message = Message.visible(current_user).where(forum_id: params.expect(:forum_id)).find(params.expect(:topic_id))
      @project = @message.project
    end

    def service
      @service ||= Messages::CreateWorkPackageService.new(user: current_user, message: @message)
    end

    def form_component(work_package)
      WorkPackages::Dialogs::CreateFormComponent.new(work_package:, project: @project, **form_urls)
    end

    def form_urls
      {
        submit_url: project_forum_topic_work_package_path(@project, @message.forum, @message),
        refresh_url: refresh_form_project_forum_topic_work_package_path(@project, @message.forum, @message)
      }
    end

    def created_flash(work_package)
      {
        message: I18n.t(:notice_successful_create),
        action_button_arguments: { tag: :a, href: work_package_path(work_package) },
        action_button_content: I18n.t("forums.topic.view_work_package", id: work_package.formatted_id)
      }
    end
  end
end
