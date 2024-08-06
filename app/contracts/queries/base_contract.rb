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

module Queries
  class BaseContract < ::ModelContract
    attribute :name

    attribute :project_id
    attribute :starred
    attribute :public # => public
    attribute :display_sums # => sums
    attribute :timeline_visible
    attribute :timeline_zoom_level
    attribute :timeline_labels
    attribute :highlighting_mode
    attribute :highlighted_attributes
    attribute :show_hierarchies
    attribute :display_representation
    attribute :include_subprojects

    attribute :column_names # => columns
    attribute :filters
    attribute :timestamps

    attribute :sort_criteria # => sortBy
    attribute :group_by # => groupBy

    attribute :ordered_work_packages # => manual sort

    def self.model
      Query
    end

    validate :validate_project
    validate :user_allowed_to_make_public
    validate :timestamps_are_parsable

    validates :name,
              presence: true,
              length: { maximum: 255 }

    def validate_project
      errors.add :project, :error_not_found if project_id.present? && !project_visible?
    end

    def project_visible?
      Project.visible(user).exists?(id: project_id)
    end

    def may_not_manage_queries?
      if model.project
        !user.allowed_in_project?(:manage_public_queries, model.project)
      else
        !user.allowed_in_any_project?(:manage_public_queries)
      end
    end

    def user_allowed_to_make_public
      # Add error only when changing public flag
      return unless model.public_changed?
      return if model.project_id.present? && model.project.nil?

      if model.public && may_not_manage_queries?
        errors.add :public, :error_unauthorized
      end
    end

    def timestamps_are_parsable
      invalid_timestamps = model.timestamps.reject(&:valid?)

      if invalid_timestamps.any?
        errors.add :timestamps, :invalid, values: invalid_timestamps.join(", ")
      end
    end
  end
end
