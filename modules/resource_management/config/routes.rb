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
  #  resources :resource_management,
  #            controller: "resource_management/resource_management",
  #            only: %i[] do
  #    collection do
  #      get "/", to: "resource_management/resource_management#overview", as: :overview
  #    end
  #  end

  scope "projects/:project_id", as: "project" do
    resources :resource_planners, controller: "resource_management/resource_planners" do
      member do
        post :toggle_public
      end

      resources :views,
                controller: "resource_management/resource_planner_views",
                only: %i[show new create edit update destroy] do
        member do
          get :new_work_package
          post :work_packages, action: :add_work_package
          put "work_packages/:work_package_id/move", action: :move_work_package, as: :move_work_package
          put "work_packages/:work_package_id/reorder", action: :reorder_work_package, as: :reorder_work_package

          delete "work_packages/:work_package_id", action: :remove_work_package, as: :remove_work_package
        end
      end

      collection do
        get "menu" => "resource_management/menus#show"
      end
    end

    resources :resource_allocations,
              controller: "resource_management/resource_allocations",
              only: %i[new create edit update destroy] do
      collection do
        get :step
        get :refresh_form
      end
    end
  end
end
