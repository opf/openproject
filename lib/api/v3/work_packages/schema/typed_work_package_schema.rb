#-- encoding: UTF-8

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

module API
  module V3
    module WorkPackages
      module Schema
        class TypedWorkPackageSchema < BaseWorkPackageSchema
          attr_reader :project, :type, :custom_fields

          def initialize(project:, type:, custom_fields: nil)
            @project = project
            @type = type
            @custom_fields = custom_fields
          end

          def milestone?
            type.is_milestone?
          end

          def available_custom_fields
            custom_fields || (project.all_work_package_custom_fields.to_a & type.custom_fields.to_a)
          end

          def no_caching?
            false
          end

          private

          def contract
            @contract ||= begin
              ::API::V3::WorkPackages::Schema::TypedSchemaContract
                .new(work_package,
                     User.current)
            end
          end

          def work_package
            @work_package ||= WorkPackage
                              .new(project: project,
                                   type: type)
          end
        end
      end
    end
  end
end
