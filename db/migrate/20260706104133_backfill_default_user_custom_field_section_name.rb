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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class BackfillDefaultUserCustomFieldSectionName < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL.squish)
      UPDATE custom_field_sections
      SET name = #{quote(default_section_name)}, updated_at = NOW()
      WHERE type = 'UserCustomFieldSection'
        AND (name IS NULL OR name = '')
    SQL
  end

  def down
    execute(<<~SQL.squish)
      UPDATE custom_field_sections
      SET name = NULL, updated_at = NOW()
      WHERE type = 'UserCustomFieldSection'
        AND name = #{quote(default_section_name)}
    SQL
  end

  private

  def default_section_name
    I18n.t("settings.user_custom_fields.label_default_section", locale: default_language)
  end

  # Settings may be unavailable when migrating a clean database (e.g. the settings
  # table or its seeds are not yet present), so fall back to English.
  def default_language
    Setting.default_language.presence || "en"
  rescue StandardError
    "en"
  end
end
