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

module Bim::Bcf::API::V2_1
  class ProjectsAPI < ::API::OpenProjectAPI
    resources :projects do
      helpers do
        def visible_projects
          Project
            .visible(current_user)
            .has_module(:bim)
        end
      end

      get &::Bim::Bcf::API::V2_1::Endpoints::Index.new(model: Project,
                                                       scope: -> { visible_projects })
                                             .mount

      route_param :id, regexp: /\A(\d+)\z/ do
        after_validation do
          @project = visible_projects
                     .find(params[:id])
        end

        get &::Bim::Bcf::API::V2_1::Endpoints::Show.new(model: Project).mount
        put &::Bim::Bcf::API::V2_1::Endpoints::Update
               .new(model: Project)
               .mount

        mount ::Bim::Bcf::API::V2_1::TopicsAPI
        mount ::Bim::Bcf::API::V2_1::ProjectExtensions::API
      end
    end
  end
end
