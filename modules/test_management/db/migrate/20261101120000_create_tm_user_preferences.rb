# frozen_string_literal: true

# Per-user choices of the Test management module (0019): "Show shortcut tips" (also set by "Don't
# show tips again") and "Show shortcut badges". Not stored in core user_preferences.settings, which
# is validated against UserPreferences::Schema (additionalProperties: false): an extra key would
# make the user's next "My account" save fail.
class CreateTmUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_user_preferences do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.jsonb :options, null: false, default: {}
      t.timestamps
    end
  end
end
