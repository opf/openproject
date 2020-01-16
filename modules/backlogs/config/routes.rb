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
  scope '', as: 'backlogs' do
    scope 'projects/:project_id', as: 'project' do
      resources :backlogs,         controller: :rb_master_backlogs,  only: :index

      resources :sprints,          controller: :rb_sprints,          only: [:show, :update] do
        resource :query,            controller: :rb_queries,          only: :show

        resource :taskboard,        controller: :rb_taskboards,       only: :show

        resource :wiki,             controller: :rb_wikis,            only: [:show, :edit]

        resource :burndown_chart,   controller: :rb_burndown_charts,  only: :show

        resources :impediments,      controller: :rb_impediments,      only: [:create, :update]

        resources :tasks,            controller: :rb_tasks,            only: [:create, :update]

        resources :export_card_configurations, controller: :rb_export_card_configurations, only: [:index, :show] do
          resources :stories,          controller: :rb_stories,          only: [:index]
        end

        resources :stories,          controller: :rb_stories,          only: [:create, :update]
      end

      resource :query, controller: :rb_queries, only: :show
    end
  end

  get 'projects/:project_id/versions/:id/edit' => 'version_settings#edit'
  post 'projects/:id/project_done_statuses' => 'projects#project_done_statuses'
  post 'projects/:id/rebuild_positions' => 'projects#rebuild_positions'
  get 'projects/:id/settings/backlogs', controller: 'backlogs_settings', action: 'show', as: 'settings_backlogs'
end
