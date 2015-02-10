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

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemasAPI < Grape::API
          resources :schemas do

            params do
              requires :id, desc: 'Work package schema id'
            end

            # The schema id is an artificial identifier that is composed of a work packages
            # project and its type (separated by a dash)
            # This allows to have a separate schema URL for each kind of different work packages
            # but with better caching capabilities than simply using the work package id as
            # identifier for the schema
            namespace ':id' do

              helpers do
                def raise404
                  message = I18n.t('api_v3.errors.code_404',
                                   type: I18n.t('api_v3.resources.schema'),
                                   id: params[:id])
                  raise ::API::Errors::NotFound.new(message)
                end
              end

              before do
                ids = params[:id].split('-')
                raise404 unless ids.size == 2 # we expect exactly two ids: project and type

                begin
                  project = Project.find(ids[0])
                  type = Type.find(ids[1])
                rescue ActiveRecord::RecordNotFound
                  raise404
                end

                authorize(:view_work_packages, context: project) do
                  raise404
                end

                schema = WorkPackageSchema.new(project: project, type: type)
                @representer = WorkPackageSchemaRepresenter.new(schema,
                                                                current_user: current_user)
              end

              get do
                @representer
              end
            end
          end
        end
      end
    end
  end
end
