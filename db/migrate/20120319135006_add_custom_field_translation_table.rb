class AddCustomFieldTranslationTable < ActiveRecord::Migration
  def self.up
    CustomField.create_translation_table! :name => :string,
                                          :default_value => :text,
                                          :possible_values => :text

    I18n.locale = Setting.default_language.to_sym
    CustomField.all.each do |f|
      f.name = f.read_attribute(:name)
      f.default_value = f.read_attribute(:default_value)
      f.possible_values = f.read_attribute(:possible_values)
      f.save
    end

    remove_column :custom_fields, :name
    remove_column :custom_fields, :default_value
    remove_column :custom_fields, :possible_values
  end

  def self.down
    add_column :custom_fields, :name, :string
    add_column :custom_fields, :default_value, :text
    add_column :custom_fields, :possible_values, :text

    I18n.locale = Setting.default_language.to_sym

    CustomField.all.each do |f|
      f.write_attribute(:name, f.name)
      f.write_attribute(:default_value, f.default_value)
      f.write_attribute(:possible_values, f.possible_values)
    end

    CustomField.drop_translation_table!
  end
end
