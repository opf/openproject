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

module API
  module V3
    module TypeSchemes
      class ProjectTypeSchemeAPI < ::API::OpenProjectAPI
        resource :type_scheme do
          put do
            authorize_in_project(:assign_type_scheme, project: @project)
            scheme_id = request_body.to_h.with_indifferent_access[:scheme_id]

            scheme = scheme_id.present? ? TypeScheme.active.find_by(id: scheme_id) : nil
            raise ::API::Errors::Validation.new(:scheme_id, "An active type scheme is required.") unless scheme

            result = ::TypeSchemes::SchemeService.assign(@project, scheme)
            raise ::API::Errors::ErrorBase.create_and_merge_errors(result.errors) if result.failure?

            status 204
            body false
          end
        end

        resource :available_types do
          get do
            authorize_in_project(:view_work_packages, project: @project)
            types = ::TypeSchemes::Resolver.allowed_types(@project, default_first: false).to_a
            ActiveRecord::Associations::Preloader.new(records: types, associations: %i[color variants]).call
            API::V3::Types::TypeCollectionRepresenter.new(types,
                                                          self_link: api_v3_paths.project_available_types(@project.id),
                                                          current_user:)
          end
        end
      end
    end
  end
end
