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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.routes.draw do
  namespace :admin do
    namespace :settings do
      resource :internal_wiki_provider, controller: "/wikis/admin/internal_wiki_provider", only: %i[show update]
      resources :wiki_providers, controller: "/wikis/admin/wiki_providers", except: [:show] do
        member do
          get :confirm_destroy
          get :edit_general_info
          delete :replace_oauth_application
        end

        resource :health_status_report, controller: "/wikis/admin/health_status", only: %i[show create] do
          post :create_health_status_report
        end

        resource :oauth_client, controller: "/wikis/admin/oauth_clients", only: %i[new create] do
          patch :update, on: :member
        end
      end
    end
  end

  resources :projects, only: %i[] do
    resources :work_packages, only: %i[] do
      resources :wikis, only: %i[] do
        collection do
          resources :tab, only: %i[index], controller: "work_package_wikis_tab", as: "wikis_tab"
        end
      end
    end
  end

  resources :relation_wiki_page_links, only: %i[create destroy], controller: "wikis/relation_page_links" do
    collection do
      get :link_existing_dialog
    end

    member do
      get :confirm_delete_dialog
    end
  end

  resource :wiki_page_link_macro, controller: "wikis/page_link_macro", only: [] do
    get :load
  end

  resource :wiki_pages, controller: "wikis/pages", only: [] do
    get :search
    get :create_new_page_dialog
    post :create_and_link
  end
end
