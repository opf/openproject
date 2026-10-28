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
  namespace :squashtm_integration do
    namespace :admin do
      resource :server, only: %i[show update destroy] do
        post :test_connection
        get :destroy_dialog
      end
    end
  end

  resources :projects, only: %i[] do
    namespace :settings do
      resource :squashtm,
               controller: "/squashtm_integration/project_settings/project_links",
               only: %i[show update destroy] do
        get :destroy_dialog
      end
    end

    resources :work_packages, only: %i[] do
      resource :squashtm_requirement_link,
               controller: "squashtm_integration/work_package_requirement_links",
               only: %i[update destroy] do
        get :destroy_dialog
      end

      resources :squashtm, only: %i[] do
        collection do
          resources :tab, only: %i[index], controller: "work_package_squashtm_tab", as: "squashtm_tab"
        end
      end
    end
  end
end
