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

    NAVIGATION_LAYOUTS = %w[vertical horizontal].freeze
    DEFAULT_NAVIGATION_LAYOUT = "vertical"
    DISPLAY_PREFIX_MAX_LENGTH = 32

    belongs_to :project

    validates :project_id, uniqueness: true
    validates :display_prefix, length: { maximum: DISPLAY_PREFIX_MAX_LENGTH }, allow_blank: true
    validate :validate_navigation_layout

    store_attribute :options, :navigation_layout, :string

    before_validation :normalize_blank_navigation_layout
    before_validation :prune_unknown_option_keys

    def self.for_project(project)
      find_or_initialize_by(project:)
    end

    def self.navigation_layout_for(project)
      for_project(project).effective_navigation_layout
    end

    def self.display_prefix_for(project)
      project.tm_setting&.display_prefix.presence ||
        Setting.plugin_openproject_test_management["default_display_prefix"]
    end

    def effective_navigation_layout
      layout = navigation_layout.presence || DEFAULT_NAVIGATION_LAYOUT
      NAVIGATION_LAYOUTS.include?(layout) ? layout : DEFAULT_NAVIGATION_LAYOUT
    end

    def vertical_navigation?
      effective_navigation_layout == "vertical"
    end

    private

    def normalize_blank_navigation_layout
      self.navigation_layout = DEFAULT_NAVIGATION_LAYOUT if navigation_layout.blank?
    end

    # Drop keys left from earlier scaffolds (e.g. enable_*) so saves stay valid.
    def prune_unknown_option_keys
      return if options.blank?

      self.options = options.stringify_keys.slice("navigation_layout")
    end

    def validate_navigation_layout
      return if NAVIGATION_LAYOUTS.include?(navigation_layout.to_s)

      errors.add(:navigation_layout, :inclusion)
    end
  end
end
