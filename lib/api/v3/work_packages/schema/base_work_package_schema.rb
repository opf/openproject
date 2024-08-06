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
        class BaseWorkPackageSchema
          def project
            nil
          end

          def type
            nil
          end

          def assignable_values(_property, _current_user)
            nil
          end

          def assignable_custom_field_values(_custom_field)
            nil
          end

          def available_custom_fields
            []
          end

          def writable?(property)
            property = property.to_s

            # Special case for milestones + date property
            property = "start_date" if property == "date" && milestone?

            @writable_attributes ||= contract.writable_attributes
            @writable_attributes.include?(property)
          end

          def milestone?
            false
          end

          def readonly?
            work_package.readonly_status?
          end

          # Alias method will not work since work_package is only defined in subclasses.
          def model
            work_package
          end

          private

          def contract
            raise NotImplementedError
          end
        end
      end
    end
  end
end
