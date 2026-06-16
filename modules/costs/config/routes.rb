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
  resources :time_entries, only: %i[create update destroy] do
    get :dialog, on: :collection
    get :dialog, on: :member
    get "/users/:user_id/tz_caption", action: :user_tz_caption, on: :collection
    post :refresh_form, on: :collection
    post :refresh_form, on: :member
  end

  scope "projects/:project_id", as: "projects" do
    resources :cost_entries, controller: "costlog", only: %i[new create]

    resources :hourly_rates, only: %i[show edit update]

    get "/time_entries/dialog" => "time_entries#dialog"
  end

  namespace "my" do
    get "/timer" => "timer#show", as: "timers"

    get "/time-tracking/(:mode-:view_mode)(/:date)" => "time_tracking#index",
        as: :time_tracking,
        constraints: {
          mode: /day|week|workweek|month/,
          view_mode: /list|calendar/,
          date: /(\d{4}-\d{2}-\d{2}|today)/
        }
    get "/time-tracking/refresh" => "time_tracking#refresh",
        as: :time_tracking_refresh
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :time_entry_activities, only: %i[show update]
      resources :cost_types, only: %i[index] do
        member { post :toggle }
      end
    end
  end

  scope "work_packages/:work_package_id", as: "work_packages" do
    resources :cost_entries, controller: "costlog", only: %i[new]
    get "/time_entries/dialog" => "time_entries#dialog"
  end

  resources :cost_entries, controller: "costlog", only: %i[edit update destroy]

  get "/cost_types", to: redirect("/admin/cost_types")

  # TODO: this is a duplicate from a route defined under project/:project_id, check whether we really want to do that
  resources :hourly_rates, only: %i[edit update]

  namespace :admin do
    namespace :settings do
      resources :time_entry_activities, except: [:show] do
        member do
          put :move
          get :reassign
        end
      end
    end

    resources :cost_types, only: %i[index new edit update create destroy] do
      member do
        # TODO: check if this can be replaced with update method
        put :set_rate
        patch :restore
        get :rates
      end

      scope module: :cost_types do
        resources :projects, controller: :cost_type_projects, only: %i[index new create]
        resource :project, controller: :cost_type_projects, only: :destroy
      end
    end

    resource :costs,
             only: %i[show update],
             controller: "costs_settings",
             as: "costs_settings"

    resource :time,
             only: %i[show update],
             controller: "time_settings",
             as: "time_settings"
  end
end
