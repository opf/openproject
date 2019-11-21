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

module ::IFCModels
  class IFCModelsController < BaseController
    include IFCModelsHelper

    before_action :find_project_by_project_id, only: %i[index new create show show_defaults edit update destroy]
    before_action :find_ifc_model_object, except: %i[index new create show_defaults]
    before_action :find_all_ifc_models, only: %i[show show_defaults]
    before_action :provision_gon, only: %i[show_defaults]

    before_action :authorize

    menu_item :ifc_models

    def index
      @ifc_models = @project
        .ifc_models
        .order('created_at ASC')
        .includes(:uploader, :project)
    end

    def new
      @ifc_model = @project.ifc_models.build
    end

    def edit; end

    def show; end

    def show_defaults
      if @ifc_models.empty?
        redirect_to "index"
      end

      @default_ifc_models = @project.ifc_models.defaults
    end

    def create
      combined_params = permitted_model_params
        .to_h
        .reverse_merge(project: @project)

      call = ::IFCModels::CreateService
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

      call = ::IFCModels::UpdateService
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

    def find_all_ifc_models
      @ifc_models = @project
                      .ifc_models
                      .order('created_at ASC')
    end

    def provision_gon
      gon.ifc_models = {
        models: @ifc_models.map do |ifc_model|
          {
            id: ifc_model.id,
            name: ifc_model.title,
            load: ifc_model.is_default
          }
        end
      }
    end

    def permitted_model_params
      params
        .fetch(:ifc_models_ifc_model, {})
        .permit('title', 'ifc_attachment', 'is_default')
    end

    def find_ifc_model_object
      @ifc_model = IFCModels::IFCModel.find_by(id: params[:id])
    end
  end
end
