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

class RepairInvalidDefaultWorkPackageCustomValues < ActiveRecord::Migration[4.2]
  class CurrentCustomField < ActiveRecord::Base
    self.table_name = "custom_fields"

    def self.find_sti_class(type_name)
      type_name = "Current#{type_name}"
      super
    end

    translates :name, :default_value, :possible_values
  end

  [
    :user, :group, :work_package, :project, :version,
    :time_entry_activity, :time_entry, :issue_priority,
  ]
    .each do |name|
      Kernel.const_set(
        "Current#{name.to_s.camelize}CustomField",
        Class.new(CurrentCustomField)
      )
    end

  def up
    unless custom_field_default_values.empty?
      create_missing_work_package_custom_values
      create_missing_work_package_customizable_journals
    end
  end

  def down
  end

  private

  def create_missing_work_package_custom_values
    missing_custom_values.each do |c|
      # Use execute instead of insert as Rails' Postgres adapter's insert fails when inserting
      # into tables ending in 'values'.
      # See https://community.openproject.org/work_packages/5033
      execute <<-SQL
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage',
                '#{c['work_package_id']}',
                '#{c['custom_field_id']}',
                '#{custom_field_default_values[c['custom_field_id']]}')
      SQL
    end
  end

  def create_missing_work_package_customizable_journals
    affected_journals.each do |c|
      insert <<-SQL
        INSERT INTO customizable_journals (journal_id, custom_field_id, value)
        VALUES ('#{c['journal_id']}',
                '#{c['custom_field_id']}',
                '#{custom_field_default_values[c['custom_field_id']]}')
      SQL
    end
  end

  def create_missing_custom_value(_table, _customized_id, _custom_field_id)
  end

  def missing_custom_values
    @missing_custom_values ||= select_all <<-SQL
      SELECT cf.id AS custom_field_id, w.id AS work_package_id
      FROM custom_fields AS cf
        JOIN custom_fields_projects AS cfp ON (cf.id = cfp.custom_field_id)
        JOIN custom_fields_types AS cft ON (cf.id = cft.custom_field_id)
        JOIN work_packages AS w ON (w.project_id = cfp.project_id
                                    AND w.type_id = cft.type_id)
        LEFT JOIN custom_values AS cv ON (cv.customized_id = w.id
                                          AND cv.customized_type = 'WorkPackage'
                                          AND cv.custom_field_id = cf.id)
      WHERE cf.id IN (#{custom_field_default_values.keys.join(', ')})
        AND cv.id IS NULL
    SQL
  end

  def custom_field_default_values
    @custom_field_default_values ||= CurrentCustomField.select { |c| !(c.default_value.blank?) }
                                     .each_with_object({}) { |c, h| h[c.id] = c.default_value unless h[c.id] }
  end

  def affected_journals
    @affected_journals ||= select_all <<-SQL
      SELECT j.id AS journal_id, cv.custom_field_id AS custom_field_id
      FROM journals AS j
        JOIN custom_values AS cv ON (j.journable_id = cv.customized_id
                                     AND j.journable_type = cv.customized_type)
        LEFT JOIN customizable_journals AS cj ON (j.id = cj.journal_id
                                                  AND cv.custom_field_id = cj.custom_field_id)
      WHERE  cv.custom_field_id IN (#{custom_field_default_values.keys.join(', ')})
        AND cv.customized_type = 'WorkPackage'
        AND cj.id IS NULL
    SQL
  end
end
