#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Bim
  module IfcModels
    class IfcModelsController < BaseController
      helper_method :gon

      before_action :find_project_by_project_id,
                    only: %i[index new create show defaults edit update destroy direct_upload_finished]
      before_action :find_ifc_model_object, only: %i[edit update destroy]
      before_action :find_all_ifc_models, only: %i[show defaults index]

      # Callback done by AWS so can't be authenticated. Don't have to be either, though.
      # It only actually does anything if there is a pending upload with the key passed by AWS.
      before_action :authorize, except: %i[direct_upload_finished set_direct_upload_file_name]
      before_action :require_login, only: [:set_direct_upload_file_name]
      skip_before_action :verify_authenticity_token, only: [:set_direct_upload_file_name] # AJAX request in page, so skip authenticity token

      menu_item :ifc_models

      def index
        @ifc_models = @ifc_models
                          .includes(:project, :uploader)
      end

      def new
        @ifc_model = @project.ifc_models.build
        prepare_form(@ifc_model)
      end

      def edit
        prepare_form(@ifc_model)
      end

      def show
        frontend_redirect params[:id].to_i
      end

      def defaults
        frontend_redirect @ifc_models.defaults.pluck(:id).uniq
      end

      def set_direct_upload_file_name
        session[:pending_ifc_model_title] = params[:title]
        session[:pending_ifc_model_is_default] = params[:isDefault]
      end

      def direct_upload_finished
        id = request.params[:key].scan(/\/file\/(\d+)\//).flatten.first
        attachment = Attachment.pending_direct_uploads.where(id: id).first
        if attachment.nil? # this should not happen
          flash[:error] = "Direct upload failed."

          redirect_to action: :new
        end

        params = {
          title: session[:pending_ifc_model_title],
          project: @project,
          ifc_attachment: attachment,
          is_default: session[:pending_ifc_model_is_default]
        }

        new_model = true
        if session[:pending_ifc_model_ifc_model_id]
          ifc_model = Bim::IfcModels::IfcModel.find_by id: session[:pending_ifc_model_ifc_model_id]
          new_model = false

          service_result = ::Bim::IfcModels::UpdateService
                               .new(user: current_user, model: ifc_model)
                               .call(params.with_indifferent_access)
        else
          service_result = ::Bim::IfcModels::CreateService
                               .new(user: current_user)
                               .call(params.with_indifferent_access)

        end
        @ifc_model = service_result.result

        session.delete :pending_ifc_model_title
        session.delete :pending_ifc_model_is_default
        session.delete :pending_ifc_model_ifc_model_id

        if service_result.success?
          ::Attachments::FinishDirectUploadJob.perform_later attachment.id

          flash[:notice] = if new_model
                             t('ifc_models.flash_messages.upload_successful')
                           else
                             t(:notice_successful_update)
                           end

          redirect_to action: :index
        else
          attachment.destroy

          flash[:error] = service_result.errors.full_messages.join(" ")

          redirect_to action: :new
        end
      end

      def create
        combined_params = permitted_model_params
                              .to_h
                              .reverse_merge(project: @project)

        service_result = ::Bim::IfcModels::CreateService
                             .new(user: current_user)
                             .call(combined_params)

        @ifc_model = service_result.result

        if service_result.success?
          flash[:notice] = t('ifc_models.flash_messages.upload_successful')
          redirect_to action: :index
        else
          @errors = service_result.errors
          render action: :new
        end
      end

      def update
        combined_params = permitted_model_params
                              .to_h
                              .reverse_merge(project: @project)

        service_result = ::Bim::IfcModels::UpdateService
                             .new(user: current_user, model: @ifc_model)
                             .call(combined_params)

        @ifc_model = service_result.result

        if service_result.success?
          flash[:notice] = t(:notice_successful_update)
          redirect_to action: :index
        else
          @errors = service_result.errors
          render action: :edit
        end
      end

      def destroy
        @ifc_model.destroy
        redirect_to action: :index
      end

      private

      def prepare_form(ifc_model)
        if OpenProject::Configuration.direct_uploads?
          @pending_upload = Attachment.create_pending_direct_upload(file_name: "model.ifc", author: current_user)
          @form = DirectFogUploader.direct_fog_hash(
            attachment: @pending_upload,
            success_action_redirect: direct_upload_finished_bcf_project_ifc_models_url
          )
          session[:pending_ifc_model_ifc_model_id] = ifc_model.id unless ifc_model.new_record?
        end
      end

      def frontend_redirect(model_ids)
        redirect_to bcf_project_frontend_path(models: JSON.dump(Array(model_ids)))
      end

      def find_all_ifc_models
        @ifc_models = @project
                          .ifc_models
                          .includes(:attachments)
                          .order("#{IfcModels::IfcModel.table_name}.created_at ASC")
      end

      def permitted_model_params
        params
            .require(:bim_ifc_models_ifc_model)
            .permit('title', 'ifc_attachment', 'is_default')
      end

      def find_ifc_model_object
        @ifc_model = Bim::IfcModels::IfcModel.find_by(id: params[:id])
      end
    end
  end
end
