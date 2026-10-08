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
end
