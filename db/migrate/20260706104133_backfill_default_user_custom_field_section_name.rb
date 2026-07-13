# frozen_string_literal: true

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
