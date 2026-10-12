# frozen_string_literal: true

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

module AI
  module AssistantSkills
    module HealthCheck
      module Rules
        # A closed descendant that still has open work packages below it.
        class ClosedDescendantWithOpenBelow < Rule
          MAX_FINDINGS = 5

          def call
            closed_ancestors_of_open_nodes
              .first(MAX_FINDINGS)
              .map do |closed|
                finding(severity: :medium,
                        area: :tree,
                        evidence: [work_package_evidence(closed)],
                        id: closed.formatted_id)
              end
          end

          private

          def closed_ancestors_of_open_nodes
            by_id = context.descendants.index_by(&:id)
            found = {}

            context.open_descendants.each do |node|
              parent = by_id[node.parent_id]
              while parent
                found[parent.id] = parent if parent.closed?
                parent = by_id[parent.parent_id]
              end
            end

            found.values.sort_by(&:id)
          end
        end
      end
    end
  end
end
