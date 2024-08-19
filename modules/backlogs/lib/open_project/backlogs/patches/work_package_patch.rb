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

module OpenProject::Backlogs::Patches::WorkPackagePatch
  extend ActiveSupport::Concern

  included do
    prepend InstanceMethods
    extend ClassMethods

    register_journal_formatted_fields "story_points", "position", formatter_key: :decimal

    validates_numericality_of :story_points, only_integer: true,
                                             allow_nil: true,
                                             greater_than_or_equal_to: 0,
                                             less_than: 10_000,
                                             if: -> { backlogs_enabled? }

    include OpenProject::Backlogs::List
  end

  module ClassMethods
    def backlogs_types
      # Unfortunately, this is not cachable so the following line would be wrong
      # @backlogs_types ||= Story.types << Task.type
      # Caching like in the line above would prevent the types selected
      # for backlogs to be changed without restarting all app server.
      (Story.types << Task.type).compact
    end

    def children_of(ids)
      where(parent_id: ids)
    end
  end

  module InstanceMethods
    def done?
      project.done_statuses.to_a.include?(status)
    end

    def to_story
      Story.find(id) if is_story?
    end

    def is_story?
      backlogs_enabled? && Story.types.include?(type_id)
    end

    def to_task
      Task.find(id) if is_task?
    end

    def is_task?
      backlogs_enabled? && (parent_id && type_id == Task.type && Task.type.present?)
    end

    def is_impediment?
      backlogs_enabled? && (parent_id.nil? && type_id == Task.type && Task.type.present?)
    end

    def types
      if is_story?
        Story.types
      elsif is_task?
        Task.types
      else
        []
      end
    end

    def story
      if is_story?
        Story.find(id)
      elsif is_task?
        ancestors.where(type_id: Story.types).first
      end
    end

    def blocks
      # return work_packages that I block that aren't closed
      return [] if closed?

      blocks_relations.includes(:to).merge(WorkPackage.with_status_open).map(&:to)
    end

    def backlogs_enabled?
      !!project.try(:module_enabled?, "backlogs")
    end

    def in_backlogs_type?
      backlogs_enabled? && WorkPackage.backlogs_types.include?(type.try(:id))
    end
  end
end

WorkPackage.include OpenProject::Backlogs::Patches::WorkPackagePatch
