class RemoveTranslationsFromCustomFields < ActiveRecord::Migration[5.0]
  require 'globalize'

  class OldCustomField < ActiveRecord::Base
    self.table_name = :custom_fields
    self.inheritance_column = nil

    translates :name
  end

  def change
    reversible do |dir|
      dir.up do
        OldCustomField.drop_translation_table! migrate_data: true
      end

      dir.down do
        OldCustomField.create_translation_table!({ name: :string }, { migrate_data: true })
      end
    end
  end
end
