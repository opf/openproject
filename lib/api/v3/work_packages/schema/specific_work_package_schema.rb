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
      module Schema
        class SpecificWorkPackageSchema < BaseWorkPackageSchema
          attr_reader :work_package

          include AssignableCustomFieldValues
          include AssignableValuesContract

          def initialize(work_package:)
            @work_package = work_package
          end

          delegate :project_id,
                   :project,
                   :type,
                   :id,
                   :milestone?,
                   :available_custom_fields,
                   to: :@work_package

          delegate :assignable_types,
                   :assignable_statuses,
                   :assignable_categories,
                   :assignable_priorities,
                   :assignable_versions,
                   :assignable_budgets,
                   to: :contract

          def no_caching?
            true
          end

          private

          def contract
            @contract ||= contract_class(work_package).new(work_package, User.current)
          end

          def contract_class(work_package)
            if work_package.new_record?
              ::WorkPackages::CreateContract
            else
              ::WorkPackages::UpdateContract
            end
          end
        end
      end
    end
  end
end
