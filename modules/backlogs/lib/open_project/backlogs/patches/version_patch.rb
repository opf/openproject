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

require_dependency 'version'

module OpenProject::Backlogs::Patches::VersionPatch
  def self.included(base)
    base.class_eval do
      has_many :version_settings, dependent: :destroy
      accepts_nested_attributes_for :version_settings

      include InstanceMethods
    end
  end

  module InstanceMethods
    def rebuild_positions(project = self.project)
      return unless project.backlogs_enabled?

      WorkPackage.transaction do
        # Remove position from all non-stories
        WorkPackage.where(['project_id = ? AND type_id NOT IN (?) AND position IS NOT NULL', project, Story.types])
          .update_all(position: nil)

        # Add work_packages w/o position to the top of the list and add
        # work_packages, that have a position, at the end
        stories_wo_position = work_packages.where(project_id: project, type_id: Story.types, position: nil).order(Arel.sql('id'))

        stories_w_position = work_packages.where(project_id: project, type_id: Story.types)
                                         .where('position IS NOT NULL')
                                         .order(Arel.sql('COALESCE(position, 0), id'))

        (stories_w_position + stories_wo_position).each_with_index do |story, index|
          story.update_column(:position, index + 1)
        end
      end

      nil
    end

    def ==(other)
      super ||
        other.is_a?(self.class) &&
          id.present? &&
          other.id == id
    end

    def eql?(other)
      self == other
    end

    def hash
      id.hash
    end
  end
end

Version.send(:include, OpenProject::Backlogs::Patches::VersionPatch)
