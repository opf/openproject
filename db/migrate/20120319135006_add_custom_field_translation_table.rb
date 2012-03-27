class AddCustomFieldTranslationTable < ActiveRecord::Migration
  def self.up
    CustomField.create_translation_table! :name => :string

    I18n.locale = Setting.default_language.to_sym
    CustomField.all.each do |f|
      f.name = f.read_attribute(:name)
      f.save
    end

    remove_column :custom_fields, :name
  end

  def self.down
    add_column :custom_fields, :name

    I18n.locale = Setting.default_language.to_sym
    CustomField.all.each do |f|
      f.write_attribute(:name, f.name)
    end

    CustomField.drop_translation_table!
  end
end
