#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
      module AvailableRelationCandidatesHelper
        include API::V3::Utilities::PathHelper

        ##
        # Queries the compatible work package's to the given one as much as possible through the
        # database.
        #
        # @param query [String] The ID or part of a subject to filter by
        # @param from [WorkPackage] The work package in the `from` position of a relation.
        # @param limit [Integer] Maximum number of results to retrieve.
        def work_package_queried(query, from, type, limit)
          like_query = query
                       .downcase
                       .split(/\s+/)
                       .map { |substr| WorkPackage.connection.quote_string(substr) }
                       .join("%")

          work_package_scope(from, type)
            .where("work_packages.id = ? OR LOWER(work_packages.subject) LIKE ?",
                   query.to_i, "%#{like_query}%")
            .limit(limit)
        end

        private

        def work_package_scope(from, type)
          canonical_type = Relation.canonical_type(type)

          if type == Relation::TYPE_RELATES
            WorkPackage.relateable_to(from).or(WorkPackage.relateable_from(from))
          elsif type != 'parent' && canonical_type == type
            WorkPackage.relateable_to(from)
          else
            WorkPackage.relateable_from(from)
          end
        end
      end
    end
  end
end
