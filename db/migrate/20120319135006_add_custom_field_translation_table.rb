#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class AddCustomFieldTranslationTable < ActiveRecord::Migration[4.2]
  def self.up
    # Added this retroactively to the migration. In the new code (Feb 2017)
    # custom fields' default value and possible values are not translated anymore.
    # Consequently this old migration fails without the following `translates` call
    # which restores the old code for the purposes of this migration.
    CustomField.send :translates, :name, :default_value, :possible_values

    CustomField.create_translation_table! name: :string,
                                          default_value: :text,
                                          possible_values: :text

    I18n.locale = Setting.default_language.to_sym
    CustomField.all.each do |f|
      f.name = f.read_attribute(:name)
      f.default_value = f.read_attribute(:default_value)
      f.possible_values = YAML::load(f.read_attribute(:possible_values))
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
