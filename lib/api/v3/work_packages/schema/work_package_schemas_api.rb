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

require 'api/v3/work_packages/schema/work_package_schema'
require 'api/v3/work_packages/schema/work_package_schema_representer'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemasAPI < ::API::OpenProjectAPI
          resources :schemas do
            params do
              requires :project, desc: 'Work package schema id'
              requires :type, desc: 'Work package schema id'
            end

            helpers do
              def raise404
                raise ::API::Errors::NotFound.new
              end
            end

            # The schema identifier is an artificial identifier that is composed of a work packages
            # project and its type (separated by a dash)
            # This allows to have a separate schema URL for each kind of different work packages
            # but with better caching capabilities than simply using the work package id as
            # identifier for the schema
            namespace ':project-:type' do
              before do
                begin
                  project = Project.find(params[:project])
                  type = Type.find(params[:type])
                rescue ActiveRecord::RecordNotFound
                  raise404
                end

                authorize(:view_work_packages, context: project) do
                  raise404
                end

                schema = WorkPackageSchema.new(project: project, type: type)
                @representer = WorkPackageSchemaRepresenter.create(schema,
                                                                   current_user: current_user)
              end

              get do
                @representer
              end
            end

            # Because the namespace declaration above does not match for shorter IDs we need
            # to catch those cases (e.g. '12' instead of '12-13') here and manually return 404
            # Otherwise we get a no route error
            namespace ':id' do
              get do
                raise404
              end
            end
          end
        end
      end
    end
  end
end
