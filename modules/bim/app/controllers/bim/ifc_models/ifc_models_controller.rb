#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

      before_action :find_project_by_project_id, only: %i[index new create show defaults edit update destroy]
      before_action :find_ifc_model_object, only: %i[edit update destroy]
      before_action :find_all_ifc_models, only: %i[show defaults index]

      before_action :authorize

      menu_item :ifc_models

      def index
        @ifc_models = @ifc_models
          .includes(:project, :uploader)
      end

      def new
        @ifc_model = @project.ifc_models.build
      end

      def edit;
      end

      def show
        frontend_redirect params[:id].to_i
      end

      def defaults
        frontend_redirect @ifc_models.defaults.pluck(:id).uniq
      end

      def create
        combined_params = permitted_model_params
          .to_h
          .reverse_merge(project: @project)

        call = ::Bim::IfcModels::CreateService
          .new(user: current_user)
          .call(combined_params)

        @ifc_model = call.result

        if call.success?
          flash[:notice] = t('ifc_models.flash_messages.upload_successful')
          redirect_to action: :index
        else
          @errors = call.errors
          render action: :new
        end
      end

      def update
        combined_params = permitted_model_params
          .to_h
          .reverse_merge(project: @project)

        call = ::Bim::IfcModels::UpdateService
          .new(user: current_user, model: @ifc_model)
          .call(combined_params)

        @ifc_model = call.result

        if call.success?
          flash[:notice] = t(:notice_successful_update)
          redirect_to action: :index
        else
          @errors = call.errors
          render action: :edit
        end
      end

      def destroy
        @ifc_model.destroy
        redirect_to action: :index
      end

      private

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
