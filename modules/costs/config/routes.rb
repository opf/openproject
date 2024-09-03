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
  scope "projects/:project_id", as: "projects" do
    resources :cost_entries, controller: "costlog", only: %i[new create]

    resources :hourly_rates, only: %i[show edit update] do
      post :set_rate, on: :member
    end
  end

  scope "my" do
    get "/timer" => "my/timer#show", as: "my_timers"
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :time_entry_activities, only: %i[show update]
    end
  end

  scope "work_packages/:work_package_id", as: "work_packages" do
    resources :cost_entries, controller: "costlog", only: %i[new]
  end

  resources :cost_entries, controller: "costlog", only: %i[edit update destroy]

  resources :cost_types, only: %i[index new edit update create destroy] do
    member do
      # TODO: check if this can be replaced with update method
      put :set_rate
      patch :restore
    end
  end

  # TODO: this is a duplicate from a route defined under project/:project_id, check whether we really want to do that
  resources :hourly_rates, only: %i[edit update]
end
