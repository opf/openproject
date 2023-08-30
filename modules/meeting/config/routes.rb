#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

OpenProject::Application.routes.draw do
  resources :projects, only: %i[] do
    resources :meetings, only: %i[index new create]
  end

  resources :meetings do
    member do
      get :cancel_edit
      put :update_title
      put :update_details
      put :update_participants
      put :change_state
    end
    resources :agenda_items, controller: 'meeting_agenda_items' do
      collection do
        get :new, action: :new, as: :new
        get :cancel_new
        # get :author_autocomplete_index
      end
      member do
        get :cancel_edit
        put :drop
        put :move
      end
    end

    resource :agenda, controller: 'meeting_agendas', only: [:update] do
      member do
        get :history
        get :diff
        put :close
        put :open
        put :notify
        put :icalendar
        post :preview
      end

      resources :versions, only: [:show],
                           controller: 'meeting_agendas'
    end

    resource :contents, controller: 'meeting_contents', only: %i[show update] do
      member do
        get :history
        get :diff
        put :notify
        get :icalendar
      end
    end

    resource :minutes, controller: 'meeting_minutes', only: [:update] do
      member do
        get :history
        get :diff
        put :notify
        post :preview
      end

      resources :versions, only: [:show],
                           controller: 'meeting_minutes'
    end

    member do
      get :copy
      match '/:tab' => 'meetings#show', :constraints => { tab: /(agenda|minutes)/ },
            :via => :get,
            :as => 'tab'
    end
  end
end
