#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Projects::Hierarchy
  extend ActiveSupport::Concern

  included do
    acts_as_nested_set order_column: :lft, dependent: :destroy

    # Keep the siblings sorted after naming changes to ensure lft sort includes name sorting
    before_save :remember_reorder
    after_save :reorder_by_name, if: -> { @reorder_nested_set }

    def reorder_by_name
      @reorder_nested_set = nil
      return unless siblings.any?

      left_neighbor = left_neighbor_by_name_order

      if left_neighbor
        move_to_right_of(left_neighbor)
      elsif self != self_and_siblings.first
        move_to_left_of(self_and_siblings.first)
      end
    end

    ##
    # Find the sibling for which the current project's name is smaller.
    # Since we sort ascending, start from the back.
    # Returns:
    #   - nil, if the current project does not have a left neighbor (should be added as first)
    #   - the project sibling for which the project should be appended to the right to
    def left_neighbor_by_name_order
      siblings
        .reverse_each
        .detect { |project| project.name.casecmp(name) == -1 }
    end

    # We need to remember if we want to reorder as nested_set
    # will perform another save directly in +after_save+ if a parent was set
    # and that clear new_record? as well as previous_new_record?
    def remember_reorder
      @reorder_nested_set = new_record? || name_changed?
    end
  end
end
