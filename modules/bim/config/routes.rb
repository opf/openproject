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

Rails.application.routes.draw do
  scope "", as: "bcf" do
    mount Bim::Bcf::API::Root => "/api/bcf"

    scope "projects/:project_id", as: "project" do
      get "bcf/menu" => "bim/menus#show"

      resources :issues, controller: "bim/bcf/issues" do
        get :upload, action: :upload, on: :collection
        post :prepare_import, action: :prepare_import, on: :collection
        post :configure_import, action: :configure_import, on: :collection
        post :import, action: :perform_import, on: :collection
      end

      # IFC viewer frontend
      get "bcf(/*state)", to: "bim/ifc_models/ifc_viewer#show", as: :frontend

      # IFC model management
      resources :ifc_models, controller: "bim/ifc_models/ifc_models" do
        collection do
          get :defaults
          get :direct_upload_finished
          post :set_direct_upload_file_name
        end
      end
    end
  end
end
