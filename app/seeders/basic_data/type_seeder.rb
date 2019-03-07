#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
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
      colors = Color.all
      colors = colors.map { |c| { c.name =>  c.id } }.reduce({}, :merge)

      type_table.map do |name, values|
        {
          name:                 I18n.t(values[5]),
          position:             values[0],
          is_default:           values[1],
          color_id:             colors[I18n.t(values[2])],
          is_in_roadmap:        values[3],
          is_milestone:         values[4]
        }
      end
    end

    def type_names
      if OpenProject::Configuration['edition'] == 'bim'
        %i[task milestone phase building_model defect approval]
      else
        %i[task milestone phase feature epic user_story bug]
      end
    end

    def type_table
      if OpenProject::Configuration['edition'] == 'bim'
        { # position is_default color_id is_in_roadmap is_milestone
          task:           [1, true, :default_color_blue,        true,  false, :default_type_task],
          milestone:      [2, true, :default_color_green_light, false, true,  :default_type_milestone],
          phase:          [3, true, :default_color_blue_dark,   false, false, :default_type_phase],
          building_model: [4, true, :default_color_blue,        true,  false, 'seeders.bim.default_type_building_model'],
          defect:         [5, true, :default_color_red,         true,  false, 'seeders.bim.default_type_defect'],
          approval:       [6, true, :default_color_grey_dark,   true,  false, 'seeders.bim.default_type_approval']
        }
      else
        { # position is_default color_id is_in_roadmap is_milestone
          task:       [1, true, :default_color_blue,        true,  false, :default_type_task],
          milestone:  [2, true, :default_color_green_light, false, true,  :default_type_milestone],
          phase:      [3, true, :default_color_blue_dark,   false, false, :default_type_phase],
          feature:    [4, true, :default_color_blue,        true,  false, :default_type_feature],
          epic:       [5, true, :default_color_orange,      true,  false, :default_type_epic],
          user_story: [6, true, :default_color_grey_dark,   true,  false, :default_type_user_story],
          bug:        [7, true, :default_color_red,         true,  false, :default_type_bug]
        }
      end
    end
  end
end
