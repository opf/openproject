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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Relations::Scopes
  module UsedForSchedulingOf
    extend ActiveSupport::Concern

    class_methods do
      # Returns all relations where:
      # - either the work package is a successor (all direct predecessors)
      # - or an automatically scheduled ancestor of the work package is a
      #   successor (all indirect predecessors)
      #
      # The automatically scheduled ancestors are the ancestors that are linked
      # to the work package only through automatically scheduled parents. As
      # soon as a parent is manually scheduled, its predecessors and ancestors
      # are not involved in scheduling anymore.
      def used_for_scheduling_of(work_package)
        return [] if work_package.nil?

        automatically_scheduled_ancestors =
          WorkPackageHierarchy.where(descendant_id: work_package.id)
                              .where.not(ancestor_id: manually_scheduled_ancestors(work_package).select(:ancestor_id))

        follows.where(from_id: automatically_scheduled_ancestors.select(:ancestor_id))
      end

      private

      def manually_scheduled_ancestors(work_package)
        manually_scheduled_ancestors = work_package.ancestors.where(schedule_manually: true)

        WorkPackageHierarchy
          .where(descendant_id: manually_scheduled_ancestors.select(:id))
      end
    end
  end
end
