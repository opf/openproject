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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module WorkPackages
      module EagerLoading
        class Principals < Base
          def apply(work_package)
            work_package.author = principal_for(work_package.author_id)
            work_package.assigned_to = principal_for(work_package.assigned_to_id)
            work_package.responsible = principal_for(work_package.responsible_id)
          end

          private

          def principal_for(principal_id)
            principals_by_id[principal_id]
          end

          def principals_by_id
            @principals_by_id ||= ::Principal
                .where(id: principal_ids)
                .to_a
                .index_by(&:id)
          end

          def principal_ids
            work_packages
              .pluck(:author_id, :assigned_to_id, :responsible_id)
              .flatten
              .uniq
              .compact
          end
        end
      end
    end
  end
end
