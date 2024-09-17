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

require_relative "20180116065518_add_hierarchy_paths"

class RemoveHierarchyPaths < ActiveRecord::Migration[5.2]
  def up
    AddHierarchyPaths.new.migrate :down

    # Set sort to id, asc where parent sort was used
    Query
      .where("sort_criteria LIKE '%parent%'")
      .find_each do |query|
      # Use update_column to ensure that value is saved regardless
      # of the overall state of the query
      query.update_column(:sort_criteria, query.sort_criteria.map { |criteria| map_parent_to_id(criteria) })
    rescue StandardError => e
      warn "Failed to migrate parent sort_criteria for query #{query.id}: #{e}"
    end
  end

  def down
    # Will fail to #rebuild_hierarchy_paths! unless restored to correct version
    AddHierarchyPaths.new.migrate :up

    # Set sort to parent, asc where query.show_hierarchies is set
    # because that is what is implied by the frontend.
    Query
      .where(show_hierarchies: true)
      .update_all(sort_criteria: [%w(parent asc)])
  end

  private

  ##
  # Map parent sort_criteria to id asc.
  def map_parent_to_id(criteria)
    if criteria.first.to_s == "parent"
      %w[id asc]
    else
      criteria
    end
  end
end
