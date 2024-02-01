# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  namespace :admin do
    namespace :settings do
      resources :storages, controller: '/storages/admin/storages', except: [:show] do
        resource :oauth_client, controller: '/storages/admin/oauth_clients', only: %i[new create] do
          patch :update, on: :member
          get :show_redirect_uri
          post :finish_setup
        end

        resource :automatically_managed_project_folders, controller: '/storages/admin/automatically_managed_project_folders',
                                                         only: %i[new create edit update]

        get :select_provider, on: :collection

        member do
          get :show_oauth_application
          get :edit_host
          get :confirm_destroy
          delete :replace_oauth_application
        end

        get :upsale, on: :collection
      end
    end
  end

  get 'projects/:project_id/project_storages/:id/open',
      controller: 'storages/project_storages',
      action: 'open',
      as: 'open_project_storage'
  scope 'projects/:project_id', as: 'project' do
    namespace 'settings' do
      resources :project_storages, controller: '/storages/admin/project_storages', except: %i[show] do
        member do
          # Destroy uses a get request to prompt the user before the actual DELETE request
          get :destroy_info, as: 'confirm_destroy'
        end

        resources :members, controller: '/storages/project_settings/project_storage_members', only: %i[index]
      end
    end
  end
end
