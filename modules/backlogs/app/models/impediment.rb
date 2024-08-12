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

class Impediment < Task
  extend OpenProject::Backlogs::Mixins::PreventIssueSti

  before_save :update_blocks_list

  validate :validate_blocks_list

  def self.default_scope
    roots
      .where(type_id: type)
  end

  def blocks_ids=(ids)
    @blocks_ids = [ids] if ids.is_a?(Integer)
    @blocks_ids = ids.split(/\D+/).map(&:to_i) if ids.is_a?(String)
    @blocks_ids = ids.map(&:to_i) if ids.is_a?(Array)
  end

  def blocks_ids
    @blocks_ids ||= blocks_relations.map(&:to_id)
  end

  private

  def update_blocks_list
    mark_blocks_to_destroy

    build_new_blocks
  end

  def validate_blocks_list
    if blocks_ids.empty?
      errors.add :blocks_ids, :must_block_at_least_one_work_package
    else
      other_version_ids = WorkPackage.where(id: blocks_ids).pluck(:version_id).uniq
      if other_version_ids.size != 1 || other_version_ids[0] != version_id
        errors.add :blocks_ids,
                   :can_only_contain_work_packages_of_current_sprint
      end
    end
  end

  def mark_blocks_to_destroy
    blocks_relations.reject { |relation| blocks_ids.include?(relation.to_id) }.each(&:mark_for_destruction)
  end

  def build_new_blocks
    (blocks_ids - blocks_relations.select { |relation| blocks_ids.include?(relation.to_id) }.map(&:to_id)).each do |id|
      blocks_relations.build(to_id: id)
    end
  end
end
