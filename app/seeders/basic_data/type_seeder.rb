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
module BasicData
  class TypeSeeder < Seeder
    def seed_data!
      Type.transaction do
        data.each do |attributes|
          Type.create!(attributes)
        end
      end
    end

    def applicable
      Type.all.any?
    end

    def not_applicable_message
      'Skipping types - already exists/configured'
    end

    ##
    # Returns the data of all types to seed.
    #
    # @return [Array<Hash>] List of attributes for each type.
    def data
      colors = PlanningElementTypeColor.all
      colors = colors.map { |c| { c.name =>  c.id } }.reduce({}, :merge)
      visibility = visibility_data

      type_table.map do |name, values|
        {
          name:                 I18n.t("default_type_#{name}"),
          position:             values[0],
          is_default:           values[1],
          color_id:             colors[I18n.t(values[2])],
          is_in_roadmap:        values[3],
          in_aggregation:       values[4],
          is_milestone:         values[5],
          attribute_visibility: visibility[name].stringify_keys
        }
      end
    end

    def type_names
      [:task, :milestone, :phase, :feature, :epic, :user_story, :bug]
    end

    def type_table
      { # position is_default color_id is_in_roadmap in_aggregation is_milestone
        task:       [1, true, :default_color_blue,        true,  false, false],
        milestone:  [2, true, :default_color_green_light, false, true,  true],
        phase:      [3, true, :default_color_blue_dark,   false, true,  false],
        feature:    [4, true, :default_color_blue,        true,  false, false],
        epic:       [5, true, :default_color_orange,      true,  true,  false],
        user_story: [6, true, :default_color_grey_dark,   true,  false, false],
        bug:        [7, true, :default_color_red,         true,  false, false]
      }
    end

    def visibility_table
      table = coded_visibility_table.map do |key, values|
        [key, values.map { |i| coded_visibility_table_value_map[i] }]
      end

      Hash[table]
    end

    def coded_visibility_table_value_map
      ['hidden', 'default', 'visible']
    end

    def coded_visibility_table
      { # columns correspond to #type_names above
        estimated_time:  [1, 1, 1, 1, 1, 1, 1],
        spent_time:      [1, 1, 1, 1, 1, 1, 1],
        percentage_done: [1, 1, 1, 1, 1, 1, 1],
        assignee:        [2, 1, 1, 2, 2, 2, 2],
        responsible:     [1, 1, 1, 1, 1, 1, 1],
        category:        [1, 1, 1, 1, 1, 1, 1],
        version:         [1, 1, 1, 2, 2, 2, 2],
        start_date:      [2, 2, 2, 1, 1, 1, 1], # mind that start_date and due_date will
        due_date:        [2, 2, 2, 1, 1, 1, 1], # affect each other - they're shown together
      }
    end

    def visibility_data
      table = visibility_table

      type_entries = type_names.map do |name|
        field_entries = table.map do |field, visibilities|
          i = type_names.index name
          [field, table[field][i] || 'default']
        end

        [name, merge_dates_for_milestones(name, Hash[field_entries])]
      end

      Hash[type_entries]
    end

    def merge_dates_for_milestones(type_name, attributes)
      if type_table[type_name].last
        attributes[:date] = attributes.delete :start_date
        attributes.delete :due_date
      end

      attributes
    end
  end
end
