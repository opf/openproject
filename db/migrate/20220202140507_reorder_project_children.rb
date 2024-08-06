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

class ReorderProjectChildren < ActiveRecord::Migration[6.1]
  class ProjectMigration < ApplicationRecord
    include ::Projects::Hierarchy
    self.table_name = "projects"
  end

  def up
    Rails.logger.info { "Resorting siblings by name in the project's nested set." }
    ProjectMigration.transaction { reorder! }
  end

  def down
    # Nothing to do
  end

  private

  def reorder!
    # Reorder the project roots
    reorder_siblings ProjectMigration.roots

    # Reorder every project hierarchy
    ProjectMigration
      .where(id: unique_parent_ids)
      .find_each { |project| reorder_siblings(project.children) }
  end

  def unique_parent_ids
    ProjectMigration
      .where.not(parent_id: nil)
      .select(:parent_id)
      .distinct
  end

  def reorder_siblings(siblings)
    return unless siblings.many?

    # Resort children manually
    sorted = siblings.sort_by { |project| project.name.downcase }

    # Get the current first child
    first = siblings.first

    sorted.each_with_index do |child, i|
      if i == 0
        child.move_to_left_of(first) unless child == first
      else
        child.move_to_right_of(sorted[i - 1])
      end
    end
  end
end
