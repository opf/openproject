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
  namespace "webhooks" do
    match ":hook_name", to: "incoming/hooks#handle_hook", via: %i(get post)
  end

  scope "admin" do
    scope :settings do
      resources :webhooks,
                param: :webhook_id,
                controller: "webhooks/outgoing/admin",
                as: "admin_outgoing_webhooks"

      resources :kubernetes_connections,
                except: %i[show],
                controller: "webhooks/kubernetes/connections",
                as: "admin_kubernetes_connections" do
        post :test, on: :member
      end

      resources :kubernetes_scripts,
                except: %i[show],
                controller: "webhooks/kubernetes/scripts",
                as: "admin_kubernetes_scripts" do
        get :permissions, on: :member
        patch :permissions, on: :member, action: :update_permissions
      end
    end
  end

  scope "work_packages/:work_package_id", as: "work_package" do
    resources :manual_scripts, only: %i[new create show], controller: "webhooks/manual_scripts" do
      get :menu, on: :collection
      post :refresh, on: :collection
    end
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :kubernetes_scripts, only: %i[show update]
    end
  end
end
