#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/projects/project_collection_representer'

module API
  module V3
    module Versions
      class ProjectsByVersionAPI < ::API::OpenProjectAPI
        resources :projects do
          before do
            @projects = @version.projects.visible(current_user).all

            # Authorization for accessing the version is done in the versions
            # endpoint into which this endpoint is embedded.
          end

          get do
            path = api_v3_paths.projects_by_version @version.id
            Projects::ProjectCollectionRepresenter.new(@projects,
                                                       @projects.count,
                                                       path)
          end
        end
      end
    end
  end
end
