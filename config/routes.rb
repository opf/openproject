#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

OpenProject::Application.routes.draw do

  scope 'projects/:project_id' do
    resources :meetings, :only => [:new, :create, :index]
  end

  resources :meetings, :except => [:new, :create, :index] do

    resource :agenda, :controller => 'meeting_agendas', :only => [:update] do
      member do
        get :history
        get :diff
        put :close
        put :open
        put :notify
        post :preview
      end

      resources :versions, :only => [:show],
                           :controller => 'meeting_agendas'
    end

    resource :minutes, :controller => 'meeting_minutes', :only => [:update] do
      member do
        get :history
        get :diff
        put :notify
        post :preview
      end

      resources :versions, :only => [:show],
                           :controller => 'meeting_minutes'
    end

    member do
      get :copy
      match '/:tab' => 'meetings#show', :constraints => { :tab => /(agenda|minutes)/ },
                                        :via => :get,
                                        :as => 'tab'
    end
  end
end
