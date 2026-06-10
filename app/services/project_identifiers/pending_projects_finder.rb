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

module ProjectIdentifiers
  # Returns the set of project IDs that still need backfilling before the
  # instance can be switched to semantic identifier mode. Three buckets:
  #
  # * projects whose identifier is not in valid semantic format
  # * projects that have work packages with no sequence_number yet
  # * projects that have work packages whose identifier doesn't match
  #   the current project prefix (stale due to renames or cross-project moves)
  module PendingProjectsFinder
    def self.project_ids
      bad_identifier_scope.ids.to_set |
        unsequenced_scope.pluck(:project_id).to_set |
        non_semantic_scope.pluck(:project_id).to_set
    end

    def self.count
      union_sql = [
        bad_identifier_scope.select("id AS project_id"),
        unsequenced_scope.select(:project_id),
        non_semantic_scope.select(:project_id)
      ].map(&:to_sql).join(" UNION ")
      Project.unscoped.from("(#{union_sql}) AS pending_projects").count
    end

    class << self
      private

      def bad_identifier_scope
        IdentifierAutofix::ProblematicIdentifiers.new.scope
      end

      def unsequenced_scope
        WorkPackage.unsequenced.distinct
      end

      def non_semantic_scope
        WorkPackage.non_semantic.distinct
      end
    end
  end
end
