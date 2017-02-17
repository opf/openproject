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
# are allowed which may be further restriced by other means other
# specific values.
class AddCustomOptions < ActiveRecord::Migration[5.0]
  class OldTranslationModel < ActiveRecord::Base
    self.table_name = :custom_field_translations

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

  def down
    drop_table table_name
  end

  def migrate_data!
    CustomOption.transaction do
      initialize_custom_options!
      migrate_values!
      migrate_journals!
    end
  end

  def initialize_custom_options!
    list_custom_fields.each do |custom_field|
      translations = custom_field_translations[custom_field.id] = get_translations custom_field

      create_custom_options_for_translations! translations
    end
  end

  def get_translations(custom_field)
    OldTranslationModel
      .where(custom_field_id: custom_field.id)
      .order(id: :asc)
  end

  def create_custom_options_for_translations!(translations)
    return if translations.empty?

    translations.first.possible_values.each_with_index.map do |value, i|
      custom_field.custom_options.create! value: value, position: i + 1
    end
  end

  def custom_field_translations
    @custom_field_translations ||= {}
  end

  def migrate_values!
    list_custom_fields.each do |custom_field|
      CustomValue.where(custom_field: custom_field).each do |custom_value|
        option_id = lookup_custom_option_id custom_value.value, custom_field.id

        custom_value.update! value: option_id.to_s if option_id
      end
    end
  end

  def migrate_journals!
    list_custom_fields.each do |custom_field|
      CustomizableJournal.where(custom_field: custom_field).each do |journal|
        option_id = lookup_custom_option_id journal.value, custom_field.id

        journal.update! value: option_id.to_s if option_id
      end
    end
  end

  def lookup_custom_option_id(value, custom_field_id)
    CustomOption
      .where(value: value, id: custom_field_id)
      .order(id: :asc)
      .limit(1)
      .pluck(:id)
      .first
  end

  def list_custom_fields
    CustomField.where(field_format: "list")
  end
end
