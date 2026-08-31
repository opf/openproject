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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.routes.draw do
  scope module: "grids" do
    # project-scoped widget routes
    scope "projects/:project_id", as: "project", constraints: { project_id: Constraints::ProjectIdentifier::REGEX } do
      namespace :widgets do
        resource :members, only: %i[show]
        resource :news, only: %i[show]
        resource :project_status, only: %i[show update]
        resource :subitems, only: %i[show]
        resource :description, only: %i[show]
      end
    end

    # global widget routes
    namespace :widgets do
      resource :news, only: %i[show]
      resource :project_favorites, controller: :favorite_projects, only: %i[show]
    end
  end
end
