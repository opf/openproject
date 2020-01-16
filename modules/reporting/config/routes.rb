#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

OpenProject::Application.routes.draw do
  scope 'projects/:project_id' do
    resources :cost_reports, except: :create do
      collection do
        match :index, via: [:get, :post]
      end

      member do
        post :update
        post :rename
      end
    end
  end

  scope 'work_packages/:work_package_id', as: 'work_packages' do
    resources :cost_entries, controller: 'work_package_costlog', only: %[index]
  end

  resources :cost_reports, except: :create do
    collection do
      match :index, via: [:get, :post]
      post :save_as, action: :create
      get :drill_down
      match :available_values, via: [:get, :post]
      get :display_report_list
    end

    member do
      post :update
      post :rename
    end
  end
end
