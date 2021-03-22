#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Relations::Scopes
  module FollowsNonManualAncestors
    extend ActiveSupport::Concern

    class_methods do
      # Returns all follows relationships of work package ancestors or work package unless
      # the ancestor or a work package between the ancestor and self is manually scheduled.
      def follows_non_manual_ancestors(work_package)
        ancestor_relations_non_manual = hierarchy_or_reflexive
                                          .where(to_id: work_package.id)
                                          .where.not(from_id: from_manual_ancestors(work_package).select(:from_id))

        where(from_id: ancestor_relations_non_manual.select(:from_id))
          .follows
      end

      private

      def from_manual_ancestors(work_package)
        manually_schedule_ancestors = work_package.ancestors.where(schedule_manually: true)

        hierarchy_or_reflexive
          .where(to_id: manually_schedule_ancestors.select(:id))
      end
    end
  end
end
