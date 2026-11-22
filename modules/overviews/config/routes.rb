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
  constraints(Constraints::ProjectIdentifier) do
    scope "projects/:project_id", as: "project" do
      scope module: "overviews" do
        resource :overview, path: "/", only: [:show] do
          get :dashboard, on: :member
        end

        resources :dashboard_pages, path: "dashboards", except: %i[index] do
          member do
            get :rename_dialog
            get :deletion_dialog
            get :save_as
            post :copy
            patch :deactivate
            patch :activate
            put :toggle_standard
          end
          get :settings, on: :collection, path: "settings"
        end

        controller :dashboard_pages do
          get "settings/dashboards/:id/edit", action: :edit, as: :edit_settings_dashboard_page
          get "settings/dashboard/edit", action: :edit, as: :edit_settings_original_dashboard
          put "settings/dashboards/:tab_key/position", action: :move, as: :move_dashboard_tab
          get "dashboard/rename_dialog", action: :rename_dialog, as: :rename_original_dashboard_dialog
          patch "dashboard/rename", action: :update, as: :rename_original_dashboard
          get "dashboard/save_as", action: :save_as, as: :save_as_original_dashboard
          post "dashboard/copy", action: :copy, as: :copy_original_dashboard
          patch "dashboard/deactivate", action: :deactivate, as: :deactivate_original_dashboard
          patch "dashboard/activate", action: :activate, as: :activate_original_dashboard
        end

        controller :overviews do
          get "project_custom_fields_sidebar" => :project_custom_fields_sidebar, as: :custom_fields_sidebar
          get "project_life_cycle_sidebar" => :project_life_cycle_sidebar, as: :life_cycle_sidebar
        end
      end
    end
  end

  namespace :admin do
    resources :dashboard_pages, path: "dashboards", only: %i[index new create edit update destroy] do
      member do
        get :rename_dialog
        get :deletion_dialog
        get :projects
        post :projects, action: :add_projects
        delete "projects/:project_id", action: :remove_project, as: :project
      end
    end
  end

  resources :project_phases, controller: "overviews/project_phases", only: %i[edit update] do
    put :preview, on: :member
  end
end
