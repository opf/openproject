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
        # Closed, while a work package it waits for is still open.
        class ClosedWithOpenPrerequisites < Rule
          PREREQUISITE_TYPES = [Relation::TYPE_BLOCKED, Relation::TYPE_FOLLOWS, Relation::TYPE_REQUIRES].freeze

          def call
            return [] unless context.closed?

            context.relations
              .select { |type, other| PREREQUISITE_TYPES.include?(type) && !other.closed? }
              .map do |type, other|
                finding(severity: :medium,
                        area: :relations,
                        evidence: [work_package_evidence(other)],
                        id: other.formatted_id,
                        relation: I18n.t(Relation::TYPES[type][:name]))
              end
          end
        end
      end
    end
  end
end
