#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Versions
      class VersionsAPI < ::API::OpenProjectAPI
        resources :versions do
          get do
            # the distinct(false) is added in order to allow ORDER BY LOWER(name)
            # which would otherwise be invalid in postgresql
            # SELECT DISTINCT, ORDER BY expressions must appear in select list
            ::API::V3::Utilities::ParamsToQuery.collection_response(Version.visible(current_user).distinct(false),
                                                                    current_user,
                                                                    params)
          end

          route_param :id do
            before do
              @version = Version.find(params[:id])

              authorized_for_version?(@version)
            end

            helpers do
              def authorized_for_version?(version)
                projects = version.projects

                permissions = %i(view_work_packages manage_versions)

                authorize_any(permissions, projects: projects, user: current_user)
              end
            end

            get do
              VersionRepresenter.new(@version, current_user: current_user)
            end

            mount ::API::V3::Versions::ProjectsByVersionAPI
          end
        end
      end
    end
  end
end
