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

Rails.application.routes.draw do
  resources :projects, only: [] do
    resources :documents, only: %i[create new index] do
      collection do
        get :menu, to: "documents/menus#show"
        get :search
      end

      resource :refresh_token, only: [:create], controller: "documents/refresh_tokens", defaults: { format: :json }
    end
  end

  resources :documents, except: %i[create new index] do
    member do
      get :edit_title, defaults: { format: :turbo_stream }
      put :update_title, defaults: { format: :turbo_stream }
      get :cancel_title_edit, defaults: { format: :turbo_stream }
      put :update_type, defaults: { format: :turbo_stream }
      get :delete_dialog
      get :render_avatars, defaults: { format: :turbo_stream }
      get :render_last_saved_at, defaults: { format: :turbo_stream }
      post :restore_version
      post :save_copy
    end

    resources :versions, only: [:index], controller: "documents/versions"
  end

  scope module: :documents do
    namespace :admin do
      namespace :settings do
        resources :document_types, except: [:show] do
          member do
            put :move
            get :delete_dialog, defaults: { format: :turbo_stream }
          end
        end

        resource :document_collaboration_settings, only: %i[show create update] do
          member do
            get :delete_dialog, defaults: { format: :turbo_stream }
            delete :destroy
          end
        end
      end
    end
  end

  namespace :admin do
    namespace :settings do
      resources :document_categories, except: [:show] do
        member do
          put :move
          get :reassign
        end
      end
    end
  end
end
