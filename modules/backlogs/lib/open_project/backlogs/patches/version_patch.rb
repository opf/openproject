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

module OpenProject::Backlogs::Patches::VersionPatch
  def self.included(base)
    base.class_eval do
      has_many :version_settings, dependent: :destroy
      accepts_nested_attributes_for :version_settings

      include InstanceMethods
    end
  end

  module InstanceMethods
    def rebuild_story_positions(project = self.project)
      return unless project.backlogs_enabled?

      WorkPackage.transaction do
        # Remove position from all non-stories
        WorkPackage.where(["project_id = ? AND type_id NOT IN (?) AND position IS NOT NULL", project, Story.types])
          .update_all(position: nil)

        rebuild_positions(work_packages.where(project_id: project), Story.types)
      end

      nil
    end

    def rebuild_task_positions(task)
      return unless task.project.backlogs_enabled?

      WorkPackage.transaction do
        # Add work_packages w/o position to the top of the list and add
        # work_packages, that have a position, at the end
        rebuild_positions(task.story.children.where(project_id: task.project), Task.type)
      end

      nil
    end

    def ==(other)
      super ||
        (other.is_a?(self.class) &&
          id.present? &&
          other.id == id)
    end

    def eql?(other)
      self == other
    end

    delegate :hash, to: :id

    def rebuild_positions(scope, type_ids)
      wo_position = scope
                      .where(type_id: type_ids,
                             position: nil)
                      .order(Arel.sql("id"))

      w_position = scope
                     .where(type_id: type_ids)
                     .where.not(position: nil)
                     .order(Arel.sql("COALESCE(position, 0), id"))

      (w_position + wo_position).each_with_index do |work_package, index|
        work_package.update_column(:position, index + 1)
      end
    end
  end
end

Version.include OpenProject::Backlogs::Patches::VersionPatch
