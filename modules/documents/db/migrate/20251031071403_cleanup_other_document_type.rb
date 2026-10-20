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

class CleanupOtherDocumentType < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        cleanup_other_document_type_if_orphaned
      end

      # No-op for down migration
    end
  end

  private

  def cleanup_other_document_type_if_orphaned
    say_with_time "Cleaning up orphaned 'Other' document type" do
      names = ["Other"]
      localised_name = localised_other_name
      names << localised_name if localised_name.present?
      placeholders = names.map { "?" }.join(", ")

      sql = <<~SQL.squish
        DELETE FROM document_types
        WHERE name IN (#{placeholders})
        AND NOT EXISTS (
          SELECT 1
          FROM documents
          WHERE documents.type_id = document_types.id
        )
      SQL

      execute OpenProject::SqlSanitization.sanitize(sql, *names)
    end
  end

  def localised_other_name
    return if Setting.default_language == "en"

    I18n.t!("seeds.common.document_categories.item_2.name", locale: Setting.default_language)
  rescue I18n::MissingTranslationData
    nil
  end
end
