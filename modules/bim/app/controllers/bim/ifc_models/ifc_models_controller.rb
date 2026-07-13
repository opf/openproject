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

module Bim
  module IfcModels
    class IfcModelsController < BaseController
      DIRECT_UPLOAD_CALLBACK_PURPOSE = "bim_ifc_models_direct_upload_callback"
      DIRECT_UPLOAD_CALLBACK_TTL = 10.minutes

      before_action :find_project_by_project_id,
                    only: %i[index new create show defaults edit update destroy direct_upload_finished]
      before_action :find_ifc_model_object, only: %i[edit update destroy]
      before_action :find_all_ifc_models, only: %i[show defaults index]

      before_action :authorize

      menu_item :ifc_models

      def index
        @ifc_models = @ifc_models
                          .includes(:project, :uploader)
      end

      def show
        frontend_redirect params[:id].to_i
      end

      def new
        @ifc_model = @project.ifc_models.build
        prepare_form(@ifc_model)
      end

      def edit
        prepare_form(@ifc_model)
      end

      def defaults
        frontend_redirect @ifc_models.defaults.pluck(:id).uniq
      end

      def set_direct_upload_file_name # rubocop:disable Metrics/AbcSize
        if params[:filesize].to_i > Setting.attachment_max_size.to_i.kilobytes
          render json: { error: I18n.t("activerecord.errors.messages.file_too_large",
                                       count: Setting.attachment_max_size.to_i.kilobytes) },
                 status: :unprocessable_entity
          return
        end

        session[:pending_ifc_model_title] = params[:title]
        session[:pending_ifc_model_is_default] = params[:isDefault]
      end

      def direct_upload_finished # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
        attachment_id = session[:pending_ifc_model_attachment_id]
        unless callback_context_valid?(attachment_id)
          fail_direct_upload
          return
        end

        attachment = Attachment.pending_direct_upload.find_by(id: attachment_id)
        if attachment.nil? || attachment.author_id != current_user.id # this should not happen
          fail_direct_upload
          return
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

        clear_pending_ifc_model_session

        if service_result.success?
          ::Attachments::FinishDirectUploadJob.perform_later attachment.id,
                                                             allowlist: false

          flash[:notice] = if new_model
                             t("ifc_models.flash_messages.upload_successful")
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
          flash[:notice] = t("ifc_models.flash_messages.upload_successful")
          redirect_to action: :index
        else
          render action: :new, status: :unprocessable_entity
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
          render action: :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @ifc_model.destroy
        redirect_to action: :index, status: :see_other
      end

      private

      def prepare_form(ifc_model) # rubocop:disable Metrics/AbcSize
        return unless OpenProject::Configuration.direct_uploads?

        call = ::Attachments::PrepareUploadService
                 .bypass_allowlist(user: current_user)
                 .call(filename: "model.ifc", filesize: 0)

        call.on_failure { flash[:error] = call.message }

        @pending_upload = call.result
        set_pending_ifc_model_callback_session
        @form = DirectFogUploader.direct_fog_hash(
          attachment: @pending_upload,
          success_action_redirect: direct_upload_finished_bcf_project_ifc_models_url(du_token: direct_upload_callback_token)
        )
        session[:pending_ifc_model_ifc_model_id] = ifc_model.id unless ifc_model.new_record?
      end

      def frontend_redirect(model_ids)
        props = Bim::Menus::DefaultQueryGeneratorService.new.call
        redirect_to bcf_project_frontend_path(models: JSON.dump(Array(model_ids)),
                                              query_props: props[:query_props],
                                              name: props[:name])
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
            .permit("title", "ifc_attachment", "is_default")
      end

      def find_ifc_model_object
        @ifc_model = @project.ifc_models.find(params[:id])
      end

      def direct_upload_callback_token
        direct_upload_callback_verifier.generate(
          {
            attachment_id: session[:pending_ifc_model_attachment_id],
            project_id: session[:pending_ifc_model_project_id],
            user_id: current_user.id,
            nonce: session[:pending_ifc_model_callback_nonce]
          },
          purpose: DIRECT_UPLOAD_CALLBACK_PURPOSE,
          expires_in: DIRECT_UPLOAD_CALLBACK_TTL
        )
      end

      def direct_upload_callback_verifier
        Rails.application.message_verifier(DIRECT_UPLOAD_CALLBACK_PURPOSE)
      end

      def set_pending_ifc_model_callback_session
        session[:pending_ifc_model_attachment_id] = @pending_upload.id
        session[:pending_ifc_model_project_id] = @project.id
        session[:pending_ifc_model_callback_nonce] = SecureRandom.hex(32)
      end

      def callback_context_valid?(attachment_id) # rubocop:disable Metrics/AbcSize
        return false if attachment_id.blank?
        return false unless attachment_id.to_s == session[:pending_ifc_model_attachment_id].to_s
        return false unless @project.id.to_s == session[:pending_ifc_model_project_id].to_s

        payload = direct_upload_callback_verifier.verified(request.params[:du_token], purpose: DIRECT_UPLOAD_CALLBACK_PURPOSE)
        return false unless payload

        expected_payload = {
          attachment_id: attachment_id.to_i,
          project_id: @project.id,
          user_id: current_user.id,
          nonce: session[:pending_ifc_model_callback_nonce]
        }.with_indifferent_access
        actual_payload = payload.with_indifferent_access.slice(:attachment_id, :project_id, :user_id, :nonce).with_indifferent_access

        actual_payload == expected_payload
      end

      def fail_direct_upload
        flash[:error] = t("bim.error_direct_upload_failed")
        redirect_to action: :new
      end

      def clear_pending_ifc_model_session
        session.delete :pending_ifc_model_title
        session.delete :pending_ifc_model_is_default
        session.delete :pending_ifc_model_ifc_model_id
        session.delete :pending_ifc_model_attachment_id
        session.delete :pending_ifc_model_project_id
        session.delete :pending_ifc_model_callback_nonce
      end
    end
  end
end
