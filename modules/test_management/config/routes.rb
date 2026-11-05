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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.routes.draw do
  scope "projects/:project_id", as: "project" do
    namespace :test_management do
      resources :test_cases do
        get :delete_dialog, defaults: { format: :turbo_stream }, on: :member
      end
      resources :suites, only: %i[index create update destroy]
      resources :test_runs do
        member do
          get :complete_dialog, defaults: { format: :turbo_stream }
          get :cancel_dialog, defaults: { format: :turbo_stream }
          get :delete_dialog, defaults: { format: :turbo_stream }
          post :complete
          post :cancel
          post :reopen
        end
        resources :run_cases, only: %i[show update], controller: "test_run_cases"
        resources :iterations, only: %i[create], controller: "test_run_iterations"
      end
      resource :project_settings, only: %i[show update], controller: "project_settings"
      resources :ci_connections, only: %i[create update destroy], path: "project_settings/ci_connections"
      resources :ci_triggers, only: %i[new create]
      get "ci", to: "ci#show", as: :ci
      get "menu", to: "menus#show"
    end
  end

  namespace :test_management do
    namespace :admin do
      resource :settings, only: %i[show update]
      resources :assistant_providers, except: %i[show] do
        post :make_default, on: :member
        collection do
          post :provider_form
          match :test_connection, via: %i[post patch]
        end
      end
    end
  end
end
