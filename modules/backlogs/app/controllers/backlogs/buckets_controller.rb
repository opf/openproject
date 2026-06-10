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

module Backlogs
  class BucketsController < BaseController
    include OpTurbo::ComponentStream

    before_action :find_backlog_bucket, only: %i[edit_dialog destroy_dialog update destroy]

    def new_dialog
      backlog_bucket = BacklogBucket.new(project: @project)

      respond_with_dialog Backlogs::BucketDialogComponent.new(backlog_bucket:)
    end

    def edit_dialog
      respond_with_dialog Backlogs::BucketDialogComponent.new(backlog_bucket: @backlog_bucket, state: :edit)
    end

    def destroy_dialog
      respond_with_dialog Backlogs::BucketDestroyModalComponent.new(backlog_bucket: @backlog_bucket)
    end

    def create
      call = ::Backlogs::Buckets::CreateService
               .new(user: current_user)
               .call(attributes: backlog_bucket_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to_backlogs
      else
        update_backlog_bucket_form_component_via_turbo_stream(backlog_bucket: call.result, base_errors: call.errors[:base])
        respond_with_turbo_streams
      end
    end

    def update
      call = ::Backlogs::Buckets::UpdateService
               .new(user: current_user, model: @backlog_bucket)
               .call(attributes: edit_backlog_bucket_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to_backlogs
      else
        update_backlog_bucket_form_component_via_turbo_stream(backlog_bucket: call.result, base_errors: call.errors[:base])
        respond_with_turbo_streams
      end
    end

    def destroy
      call = ::Backlogs::Buckets::DeleteService
               .new(user: current_user, model: @backlog_bucket)
               .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end

      redirect_to_backlogs
    end

    private

    def update_backlog_bucket_form_component_via_turbo_stream(backlog_bucket:, base_errors: nil)
      update_via_turbo_stream(
        component: Backlogs::BucketFormComponent.new(
          backlog_bucket:,
          base_errors:
        ),
        status: :bad_request
      )
    end

    def find_backlog_bucket
      @backlog_bucket = BacklogBucket.where(project: @project).find(params[:id])
    end

    def backlog_bucket_params
      edit_backlog_bucket_params.merge(project: @project)
    end

    def edit_backlog_bucket_params
      params.expect(backlog_bucket: %i[name])
    end

    def redirect_to_backlogs
      render turbo_stream: turbo_stream.redirect_to(
        project_backlogs_backlog_path(@project, helpers.all_backlogs_params)
      )
    end
  end
end
