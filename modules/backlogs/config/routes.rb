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
  scope "", as: "backlogs" do
    scope "projects/:project_id", as: "project" do
      resources :backlogs,         controller: :rb_master_backlogs,  only: :index

      resources :sprints,          controller: :rb_sprints,          only: %i[show update] do
        resource :query,            controller: :rb_queries,          only: :show

        resource :taskboard,        controller: :rb_taskboards,       only: :show

        resource :wiki,             controller: :rb_wikis,            only: %i[show edit]

        resource :burndown_chart,   controller: :rb_burndown_charts,  only: :show

        resources :impediments,      controller: :rb_impediments,      only: %i[create update]

        resources :tasks,            controller: :rb_tasks,            only: %i[create update]

        resources :stories, controller: :rb_stories, only: %i[create update]
      end

      resource :query, controller: :rb_queries, only: :show
    end
  end

  scope "projects/:project_id", as: "project", module: "projects" do
    namespace "settings" do
      resource :backlogs, only: %i[show update] do
        member do
          post "rebuild_positions" => "backlogs#rebuild_positions"
        end
      end
    end
  end

  get "projects/:project_id/versions/:id/edit" => "version_settings#edit"

  scope "admin" do
    resource :backlogs,
             only: %i[show update],
             controller: :backlogs_settings,
             as: "admin_backlogs_settings"
  end
end
