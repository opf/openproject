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
    module WorkPackages
      class FormRepresenter < ::API::Decorators::Form
        def payload_representer
          WorkPackagePayloadRepresenter
            .create(represented, current_user:)
        end

        def schema_representer
          schema = Schema::SpecificWorkPackageSchema.new(work_package: represented)
          schema_link = api_v3_paths.work_package_schema(represented.project_id,
                                                         represented.type_id)
          Schema::WorkPackageSchemaRepresenter.create(schema,
                                                      self_link: nil,
                                                      form_embedded: true,
                                                      base_schema_link: schema_link,
                                                      current_user:)
        end
      end
    end
  end
end
