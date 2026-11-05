# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  class ProjectSetting < ApplicationRecord
    self.table_name = "tm_project_settings"

    FOLDER_TREE_LAYOUTS = %w[split_pane sidebar].freeze
    DEFAULT_FOLDER_TREE_LAYOUT = "split_pane"
    FEATURES = %w[ci milestones test_plans test_assistant].freeze

    belongs_to :project

    validates :project_id, uniqueness: true
    validate :validate_folder_tree_layout

    store_accessor :options, :folder_tree_layout, *FEATURES.map { "enable_#{it}" }

    before_validation :normalize_blank_folder_tree_layout

    def self.for_project(project)
      find_or_initialize_by(project:)
    end

    def self.folder_tree_layout_for(project)
      for_project(project).effective_folder_tree_layout
    end

    def self.display_prefix_for(project)
      project.tm_setting&.display_prefix.presence ||
        Setting.plugin_openproject_test_management["default_display_prefix"]
    end

    def self.enabled?(project, feature)
      project.present? && find_by(project:)&.enabled?(feature) != false
    end

    def enabled?(feature)
      !ActiveModel::Type::Boolean.new.cast(options["enable_#{feature}"]).equal?(false)
    end

    def effective_folder_tree_layout
      layout = folder_tree_layout.presence || DEFAULT_FOLDER_TREE_LAYOUT
      FOLDER_TREE_LAYOUTS.include?(layout) ? layout : DEFAULT_FOLDER_TREE_LAYOUT
    end

    def split_pane_layout?
      effective_folder_tree_layout == "split_pane"
    end

    def sidebar_layout?
      effective_folder_tree_layout == "sidebar"
    end

    private

    def normalize_blank_folder_tree_layout
      self.folder_tree_layout = DEFAULT_FOLDER_TREE_LAYOUT if folder_tree_layout.blank?
    end

    def validate_folder_tree_layout
      return if FOLDER_TREE_LAYOUTS.include?(folder_tree_layout.to_s)

      errors.add(:folder_tree_layout, :inclusion)
    end
  end
end
