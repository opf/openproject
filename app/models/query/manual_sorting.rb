#-- encoding: UTF-8

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
#
module Query::ManualSorting
  extend ActiveSupport::Concern

  included do
    include Concerns::VirtualAttribute
    after_save :persist_ordered_work_packages!

    virtual_attribute :ordered_work_packages do
      ::OrderedWorkPackage
        .where(query_id: id)
        .order(:position)
        .pluck(:work_package_id)
    end

    def manually_sorted?
      sort_criteria_columns.any? { |clz, _| clz.is_a?(::Queries::WorkPackages::Columns::ManualSortingColumn) }
    end

    private

    def self.manual_sorting_column
      ::Queries::WorkPackages::Columns::ManualSortingColumn.new
    end
    delegate :manual_sorting_column, to: :class

    ##
    # Replace the current set of ordered work packages
    def persist_ordered_work_packages!
      return unless previous_changes[:ordered_work_packages]

      OrderedWorkPackage.transaction do
        ::OrderedWorkPackage.where(query_id: id).delete_all
        store_ordered_work_packages!
      end
    end

    ##
    # Bulk insert the current set of ordered IDs
    def store_ordered_work_packages!
      bulk = ordered_work_packages.each_with_index.map do |wp_id, position|
        {
          query_id: id,
          work_package_id: wp_id,
          position: position
        }
      end

      OrderedWorkPackage.import bulk
    end
  end
end
