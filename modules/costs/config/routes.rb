#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'projects' do
    resources :cost_entries, controller: 'costlog', only: [:new, :create]

    resources :cost_objects, only: [:new, :create, :index] do
      post :update_labor_budget_item, on: :collection
      post :update_material_budget_item, on: :collection
    end

    resources :hourly_rates, only: [:show, :edit, :update] do
      post :set_rate, on: :member
    end
  end

  scope 'work_packages/:work_package_id', as: 'work_packages' do
    resources :cost_entries, controller: 'costlog', only: %i[new]
  end

  resources :cost_entries, controller: 'costlog', only: [:edit, :update, :destroy]

  resources :cost_objects, only: [:show, :update, :destroy, :edit] do
    get :copy, on: :member
  end

  resources :cost_types, only: [:index, :new, :edit, :update, :create, :destroy] do
    member do
      # TODO: check if this can be replaced with update method
      put :set_rate
      patch :restore
    end
  end

  # TODO: this is a duplicate from a route defined under project/:project_id, check whether we really want to do that
  resources :hourly_rates, only: [:edit, :update]
end
