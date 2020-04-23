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

module Constants
  class ARToAPIConversions
    WELL_KNOWN_CONVERSIONS = {
      assigned_to: 'assignee',
      version: 'version',
      done_ratio: 'percentageDone',
      estimated_hours: 'estimatedTime',
      created_on: 'createdAt',
      updated_on: 'updatedAt',
      remaining_hours: 'remainingTime',
      spent_hours: 'spentTime',
      subproject: 'subprojectId',
      relation_type: 'type',
      mail: 'email',
      column_names: 'columns',
      is_public: 'public',
      sort_criteria: 'sortBy',
      message: 'post'
    }.freeze

    class << self
      def add(map)
        conversions.push(map)
      end

      def all
        conversions.inject(:merge)
      end

      private

      def conversions
        @conversions ||= [WELL_KNOWN_CONVERSIONS]
      end
    end
  end
end
