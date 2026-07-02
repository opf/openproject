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
  rails_relative_url_root = OpenProject::Configuration["rails_relative_url_root"] || ""
  backlogs_redirect = lambda do |params, request, target|
    query = request.query_string.presence
    path = "#{rails_relative_url_root}/projects/#{params[:project_id]}/backlogs/#{target}"

    query ? "#{path}?#{query}" : path
  end

  scope "admin" do
    resource :backlogs, only: :show, controller: "backlogs/settings", as: "admin_backlogs_settings"
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :backlog_sharing, only: %i[show update]
    end
  end

  resources :projects, only: [] do
    get "backlogs",
        to: redirect { |params, request| backlogs_redirect.call(params, request, "backlog") },
        as: :backlogs

    # TODO: Remove these legacy (version 17.3) compatibility redirects in OpenProject 18.
    get "sprints/:sprint_id/taskboard",
        to: redirect { |params, request| backlogs_redirect.call(params, request, "sprints/#{params[:sprint_id]}/taskboard") }
    get "sprints/:sprint_id/burndown_chart",
        to: redirect { |params, request| backlogs_redirect.call(params, request, "sprints/#{params[:sprint_id]}/burndown_chart") }

    namespace :backlogs do
      resource :backlog, controller: :backlog, only: :show
      get "backlog/details/:work_package_id(/:tab)",
          to: "backlog#details",
          as: :backlog_details,
          work_package_split_view: true,
          constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT },
          defaults: { tab: :overview }

      resources :buckets, only: %i[create update destroy] do
        collection do
          get :new_dialog
        end

        member do
          get :edit_dialog
          get :destroy_dialog
        end
      end

      resources :sprints, param: :sprint_id, only: %i[index create update] do
        collection do
          get :new_dialog
          get :refresh_form
        end

        member do
          post :start
          post :finish
          get :edit_dialog
        end
      end

      resources :work_packages, controller: :work_packages, only: [] do
        member do
          get :menu
          put :move
          get :move_to_sprint_dialog
          get :move_to_bucket_dialog
        end
      end

      scope "sprints/:sprint_id" do
        get "taskboard", to: "taskboard#show", as: :sprint_taskboard
        get "burndown_chart", to: "burndown_chart#show", as: :sprint_burndown_chart
      end
    end
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :backlogs, only: %i[show update] do
        member do
          post "rebuild_positions" => "backlogs#rebuild_positions"
        end
      end
    end
  end
end
