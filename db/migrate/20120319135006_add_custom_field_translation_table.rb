class AddCustomFieldTranslationTable < ActiveRecord::Migration
  def self.up
    CustomField.create_translation_table! :name => :string,
                                          :default_value => :text

    I18n.locale = Setting.default_language.to_sym
    CustomField.all.each do |f|
      f.name = f.read_attribute(:name)
      f.default_value = f.read_attribute(:default_value)
      f.save
    end

    remove_column :custom_fields, :name
    remove_column :custom_fields, :default_value
  end

  def self.down
    add_column :custom_fields, :name, :string
    add_column :custom_fields, :default_value, :text

    I18n.locale = Setting.default_language.to_sym

    CustomField.all.each do |f|
      f.write_attribute(:name, f.name)
      f.write_attribute(:default_value, f.default_value)
    end

    CustomField.drop_translation_table!
  end
end
