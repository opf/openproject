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
    resources :gantt, controller: "gantt/gantt", only: [:index] do
      collection do
        # The menu route has to be above the state routes! Otherwise, the menu will be interpreted as another state
        get "menu" => "gantt/menus#show"
        get "/export_dialog" => "work_packages#export_dialog"

        get "details/:work_package_id(/:tab)" => "gantt/gantt#split_view", as: :details,
            defaults: { tab: "overview" }, work_package_split_view: true,
            constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT }

        get "/create_new" => "gantt/gantt#split_create", as: "new_split", work_package_split_create: true
      end
    end
  end

  resources :gantt, controller: "gantt/gantt", only: [:index] do
    collection do
      get "/export_dialog" => "work_packages#export_dialog"

      get "details/:work_package_id(/:tab)" => "gantt/gantt#split_view", as: :details,
          defaults: { tab: "overview" }, work_package_split_view: true,
          constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT }

      get "/create_new" => "gantt/gantt#split_create", as: "new_split", work_package_split_create: true

      get "/" => "gantt/gantt#index", as: "index"
    end
  end

  namespace :gantt do
    resource :menu, only: %[show]
  end
end
