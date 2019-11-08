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

    before_action :find_project_by_project_id, only: %i[index new create show edit update destroy]
    before_action :find_ifc_model_object, except: %i[index new create]

    before_action :authorize

    menu_item :ifc_models

    def index
      @ifc_models = @project
        .ifc_models
        .order('updated_at DESC')
        .includes(:uploader, :project)
    end

    def new
      @ifc_model = @project.ifc_models.build(ifc_model_params)
    end

    def edit; end

    def show; end

    def create
      @ifc_model = @project.ifc_models.build(uploader: User.current)

      if add_attachment && @ifc_model.save
        redirect_to action: :show, id: @ifc_model.id
      else
        render action: :new
      end
    end

    def update
      if @ifc_model.update(ifc_model_params)
        redirect_to action: :show, id: @ifc_model.id
      else
        render action: :edit
      end
    end

    def destroy
      @ifc_model.destroy
      redirect_to action: :index
    end

    private

    def add_attachment
      if (file = ifc_model_params['ifc_attachment']) && file && file.size.positive?
        @ifc_model.ifc_attachment = file
        @ifc_model.title = file.original_filename
      else
        flash[:error] = t('ifc_models.could_not_save_file')
        false
      end
    end

    def ifc_model_params
      params.fetch(:ifc_models_ifc_model, {}).permit('title', 'ifc_attachment')
    end

    def find_ifc_model_object
      @ifc_model = IFCModels::IFCModel.find_by(id: params[:id])
    end
  end
end
