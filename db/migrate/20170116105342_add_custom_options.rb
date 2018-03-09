#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Adds a table for storing possible values (options) for custom fields.
# If a custom field has no possible values then arbitrary values
# are allowed which may be further restriced by other means other than
# specific values.
class AddCustomOptions < ActiveRecord::Migration[5.0]
  require 'globalize'

  class OldCustomField < ActiveRecord::Base
    self.table_name = :custom_fields
    self.inheritance_column = nil

    translates :name, :default_value, :possible_values
  end

  class OldCustomField::Translation
    serialize :possible_values, Array
  end

  def table_name
    :custom_options
  end

  def up
    create_table table_name do |t|
      t.integer :custom_field_id
      t.integer :position
      t.boolean :default_value
      t.text :value
    end

    migrate_data!

    add_column :custom_fields, :multi_value, :boolean, default: false
    add_column :custom_fields, :default_value, :text

    remove_column :custom_field_translations, :default_value
    remove_column :custom_field_translations, :possible_values # replaced by custom options
  end

  ##
  # Dropping the translations for custom field default values and possible values is irreversible.
  # We can just create one default translation.
  def down
    CustomOption.transaction do
      add_column :custom_field_translations, :default_value, :text
      add_column :custom_field_translations, :possible_values, :text

      rollback_custom_fields!
      rollback_values!
      rollback_journals!

      remove_column :custom_fields, :multi_value
      remove_column :custom_fields, :default_value

      drop_table table_name
    end
  end

  def migrate_data!
    say "Migrating #{list_custom_fields.length} custom fields of type list. This will take a while, please be patient."
    CustomOption.transaction do
      initialize_custom_options!
    end
    migrate_all_values!
  end

  def initialize_custom_options!
    list_custom_fields.each do |custom_field|
      translations = custom_field_translations[custom_field.id] = get_translations custom_field

      create_custom_options_for_translations! translations, custom_field
    end
  end

  def get_translations(custom_field)
    OldCustomField::Translation
      .where(custom_field_id: custom_field.id)
      .order(id: :asc)
  end

  def create_custom_options_for_translations!(translations, custom_field)
    return if translations.empty?

    # we don't support translations anymore, assume first as canonical
    translation = translations.first

    if translation.possible_values.is_a? String
      translation.possible_values = YAML.load translation.possible_values
    end

    translation.possible_values.each_with_index.map do |value, i|
      custom_field.custom_options.create!(
        value: value,
        position: i + 1,
        default_value: (value == translation.default_value)
      )
    end
  end

  def custom_field_translations
    @custom_field_translations ||= {}
  end

  def migrate_all_values!
    list_custom_fields.each do |custom_field|
      name = custom_field.translations.first.name rescue custom_field.id
      id_map = custom_values_id_map(custom_field.id)

      say_with_time "Migrating CF '#{name}'" do
        CustomField.transaction do
          migrate_values!(custom_field, id_map)
          migrate_journals!(custom_field, id_map)
        end
      end
    end
  end

  def migrate_values!(custom_field, id_map)
    CustomValue.where(custom_field: custom_field).each do |custom_value|
      option_id = id_map[custom_value.value]

      custom_value.update_columns(value: option_id.to_s) if option_id
    end
  end

  def migrate_journals!(custom_field, id_map)
    CustomizableJournal.where(custom_field: custom_field).each do |journal|
      option_id = id_map[journal.value]

      journal.update_columns(value: option_id.to_s) if option_id
    end
  end

  def rollback_custom_fields!
    Globalize.with_locale(Setting.default_language.to_sym) do
      rollback_list_custom_fields!
      rollback_other_custom_fields!
    end
  end

  def rollback_list_custom_fields!
    OldCustomField.where(field_format: "list").each do |old_custom_field|
      new_custom_field = CustomField.find old_custom_field.id

      old_custom_field.default_value =
        new_custom_field.custom_options.select(&:default_value?).map(&:value).first
      old_custom_field.possible_values =
        new_custom_field.custom_options.map(&:value)

      old_custom_field.save
    end
  end

  def rollback_other_custom_fields!
    OldCustomField.where.not(field_format: "list").each do |old_custom_field|
      new_custom_field = CustomField.find old_custom_field.id

      old_custom_field.default_value = new_custom_field.default_value

      old_custom_field.save
    end
  end

  def rollback_values!
    list_custom_fields.each do |custom_field|
      CustomValue.where(custom_field: custom_field).each do |custom_value|
        option_value = CustomOption.find_by(id: custom_value.value, custom_field_id: custom_field.id).try(:value)

        if option_value
          custom_value.value = option_value
          custom_value.save(validate: false) # with the new code the validation will fail as an ID is expected
        end
      end
    end
  end

  def rollback_journals!
    list_custom_fields.each do |custom_field|
      CustomizableJournal.where(custom_field: custom_field).each do |journal|
        option_value = CustomOption.find_by(id: journal.value, custom_field_id: custom_field.id).try(:value)

        journal.update! value: option_value if option_value
      end
    end
  end

  def custom_values_id_map(custom_field_id)
    values = CustomOption
              .where(custom_field_id: custom_field_id)
              .pluck(:value, :id)

    Hash[values]
  end

  def list_custom_fields
    @list_custom_fields ||= CustomField.where(field_format: "list")
  end
end
