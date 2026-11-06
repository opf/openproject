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

class UpdateDefaultAccentAndHeaderColors < ActiveRecord::Migration[8.1]
  class MigrationDesignColor < ApplicationRecord
    self.table_name = "design_colors"
  end

  class MigrationCustomStyle < ApplicationRecord
    self.table_name = "custom_styles"
  end

  OLD_COLORS = {
    "accent-color" => "#1A67A3",
    "header-bg-color" => "#1A67A3",
    "main-menu-bg-selected-background" => "#175A8E"
  }.freeze

  NEW_COLORS = {
    "accent-color" => "#0F41B5",
    "header-bg-color" => "#0F41B5",
    "main-menu-bg-selected-background" => "#0F41B5"
  }.freeze

  def up
    replace_colors(from: OLD_COLORS, to: NEW_COLORS)
  end

  def down
    replace_colors(from: NEW_COLORS, to: OLD_COLORS)
  end

  private

  def replace_colors(from:, to:)
    updated = from.sum do |variable, hexcode|
      MigrationDesignColor
        .where(variable:, hexcode:)
        .update_all(hexcode: to.fetch(variable), updated_at: Time.current)
    end

    touch_current_custom_style if updated.positive?
  end

  # Cached custom styles are keyed on the current CustomStyle, which
  # DesignColor's after_commit hook would otherwise touch.
  def touch_current_custom_style
    MigrationCustomStyle.order(created_at: :desc).first&.touch
  end
end
