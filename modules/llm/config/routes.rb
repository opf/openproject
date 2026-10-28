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
  scope "admin" do
    resource :llm_connection, only: %i[show update], controller: "admin/llm_connections" do
      collection do
        delete :api_key, action: :delete_api_key
        get :delete_api_key_dialog
        get :disconnect_dialog
        post :disconnect
      end

      resource :health_status_report, only: %i[show create], controller: "admin/llm_health_status" do
        post :create_health_status_report
      end
    end

    resources :llm_models, only: %i[index new create edit update destroy], controller: "admin/llm_models" do
      collection do
        get :search, defaults: { format: :turbo_stream }
        post :refresh
        patch :defaults, action: :update_defaults
      end

      member do
        get :delete_dialog
      end
    end

    # Keyed by feature key rather than by record id: the binding is an attribute
    # of a registered feature, and a feature may not have a row yet.
    resources :llm_feature_bindings, only: %i[index update], controller: "admin/llm_feature_bindings"
  end

  namespace :admin do
    resources :ai_assistants, except: :show do
      post :copy, on: :member
      resources :skills, controller: "ai_assistant_skills", except: %i[index show] do
        post :copy, on: :member
      end
    end
  end

  # AI Assistance in the app header. The place (work_package_id or project_id) is a query
  # parameter, because the menu is the same on every page.
  resource :ai_assistance_menu, path: "ai_assistance/menu", controller: "ai_assistance/menus", only: :show
  resource :ai_assistance_chat, path: "ai_assistance/chat", controller: "ai_assistance/chats", only: %i[show create] do
    post :messages, action: :send_message
    post :start
    post :rerun
    get :poll
    get :history
    post "proposals/:proposal_id/apply", action: :apply, as: :apply_proposal
    post "proposals/:proposal_id/dismiss", action: :dismiss, as: :dismiss_proposal
  end

  namespace :my do
    resources :ai_assistants, except: :show do
      post :copy, on: :member
      resources :skills, controller: "ai_assistant_skills", except: %i[index show] do
        post :copy, on: :member
      end
    end
  end
end
