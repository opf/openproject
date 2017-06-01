class RemoveTranslationsFromCustomFields < ActiveRecord::Migration[5.0]
  require 'globalize'

  class OldCustomField < ActiveRecord::Base
    self.table_name = :custom_fields
    self.inheritance_column = nil

    translates :name
  end

  class NewCustomField < ActiveRecord::Base
    self.table_name = :custom_fields
    self.inheritance_column = nil
  end

  def get_globalize_fallbacks
    first_defined_locale = {}
    OldCustomField::Translation.pluck(:custom_field_id, :name).each do |id, name|
      next if first_defined_locale[id]
      first_defined_locale[id] = name
    end

    first_defined_locale
  end

  def change
    reversible do |dir|
      dir.up do
        names = get_globalize_fallbacks
        OldCustomField.drop_translation_table! migrate_data: true

        NewCustomField.transaction do
          NewCustomField.where(name: nil).each do |cf|
            say "Custom field #{cf.id} is missing translation for #{I18n.locale}: Falling back to #{names[cf.id]}"
            cf.update_attribute(:name, names[cf.id] || "Custom field #{cf.id}")
          end
        end
      end

      dir.down do
        OldCustomField.create_translation_table!({ name: :string }, { migrate_data: true })
      end
    end
  end
end
