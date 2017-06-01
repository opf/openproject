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

require_relative 'migration_utils/timelines'

class MigrateTimelinesOptions < ActiveRecord::Migration[4.2]
  include Migration::Utils

  COLUMN = 'options'

  OPTIONS = {
    # already done in 20131015064141_migrate_timelines_end_date_property_in_options.rb
    # 'end_date' => 'due_date',
    'planning_element_types' => 'type',
    'project_type' => 'type',
    'project_status' => 'status',
  }

  def up
    say_with_time_silently 'Check for historical comparisons' do
      comparisons = timelines_with_historical_comparisons

      unless comparisons.empty?
        affected_ids = comparisons.map(&:id)

        raise 'Error: Cannot migrate timelines options!'\
              "\n\n"\
              "Timelines exist that use historical comparison. This is not\n"\
              "supported in future versions of timelines.\n\n"\
              "The affected timelines ids are: #{affected_ids}\n\n"\
              'You may use the rake task '\
              "'migrations:timelines:remove_timelines_historical_comparison_from_options' "\
              "to prepare the\n"\
              'current schema for this migration.'\
              "\n\n\n"
      end
    end

    say_with_time_silently 'Update timelines options' do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_timelines_options(OPTIONS,
                                                                    pe_id_map,
                                                                    pe_type_id_map)),
                           nil)
    end

    if contains_none_element?
      puts "\n\n"\
           'ATTENTION:'\
           "\n\n"\
           "The timelines configurations reference the 'none' type. The\n"\
           "'none' type is created in the production seed. Thus, AFTER the\n"\
           "production seed, you need to run rake task\n"\
           "'migrations:timelines:fix_missing_none_type_in_timelines_config'."\
           "\n\n\n\n"
    end
  end

  def down
    say_with_time_silently 'Restore timelines options' do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_timelines_options(OPTIONS.invert,
                                                                    pe_id_map.invert,
                                                                    pe_type_id_map.invert)),
                           nil)
    end
  end

  def contains_none_element?
    @contains_none_element
  end

  def contains_none_element=(value)
    @contains_none_element = value
  end

  private

  PE_TYPE_KEY = 'planning_element_types'
  PE_TIME_TYPE_KEY = 'planning_element_time_types'
  VERTICAL_PE_TYPES = 'vertical_planning_elements'

  def migrate_timelines_options(options, pe_id_map, pe_type_id_map)
    calling_class = self

    Proc.new do |timelines_opts|
      timelines_opts = rename_columns timelines_opts, options
      timelines_opts = migrate_planning_element_types timelines_opts, pe_type_id_map, calling_class
      timelines_opts = migrate_planning_element_time_types timelines_opts, pe_type_id_map
      timelines_opts = migrate_vertical_planning_elements timelines_opts, pe_id_map

      timelines_opts
    end
  end

  def migrate_planning_element_types(timelines_opts, pe_type_id_map, calling_class)
    pe_types = []

    pe_types =  timelines_opts[PE_TYPE_KEY].delete_if(&:nil?) if timelines_opts.has_key? PE_TYPE_KEY

    calling_class.contains_none_element = calling_class.contains_none_element? || pe_types.empty?

    pe_types = pe_types.empty? ? new_ids_of_former_pes : pe_types.map { |p| pe_type_id_map[p.to_i].to_s }

    timelines_opts[PE_TYPE_KEY] = pe_types

    timelines_opts
  end

  def migrate_planning_element_time_types(timelines_opts, pe_type_id_map)
    return timelines_opts unless timelines_opts.has_key? PE_TIME_TYPE_KEY

    pe_time_types = timelines_opts[PE_TIME_TYPE_KEY]

    pe_time_types.map! do |p| pe_type_id_map[p.to_i].to_s end

    timelines_opts[PE_TIME_TYPE_KEY] = pe_time_types

    timelines_opts
  end

  def migrate_vertical_planning_elements(timelines_opts, pe_id_map)
    return timelines_opts unless timelines_opts.has_key? VERTICAL_PE_TYPES

    vertical_pes = timelines_opts[VERTICAL_PE_TYPES].split(',')
                   .map(&:strip)

    unless vertical_pes.empty?
      mapped_pes = vertical_pes.map { |v| pe_id_map[v.to_i] }
                   .compact

      timelines_opts[VERTICAL_PE_TYPES] = mapped_pes.join(',')
    end

    timelines_opts
  end

  def new_ids_of_former_pes
    # don't forget '0' for 'none' type
    @new_ids_of_former_pes ||= pe_types_ids_with_new_ids.each_with_object([0]) do |i, l|
      l << i['new_id']
    end
  end

  def pe_type_id_map
    @pe_type_id_map ||= pe_types_ids_with_new_ids.each_with_object(-1 => 0) do |r, h|
      h[r['id']] = r['new_id']
    end
  end

  def pe_types_ids_with_new_ids
    select_all <<-SQL
      SELECT id, new_id
      FROM legacy_planning_element_types
    SQL
  end

  def pe_id_map
    @pe_id_map ||= pe_ids_with_new_ids.each_with_object({}) do |r, h|
      h[r['id']] = r['new_id']
    end
  end

  def pe_ids_with_new_ids
    select_all <<-SQL
      SELECT id, new_id
      FROM legacy_planning_elements
    SQL
  end
end
