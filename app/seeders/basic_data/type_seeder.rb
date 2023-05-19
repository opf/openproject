#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++
module BasicData
  class TypeSeeder < Seeder
    self.needs = [
      BasicData::ColorSeeder,
      BasicData::ColorSchemeSeeder
    ]

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
      colors = Color.pluck(:name, :id).to_h

      type_table.map do |_name, (position, is_default, color_name, is_in_roadmap, is_milestone, type_name)|
        {
          name: I18n.t(type_name),
          position:,
          is_default:,
          color_id: colors.fetch(color_name),
          is_in_roadmap:,
          is_milestone:,
          description: ''
        }
      end
    end

    def type_names
      raise NotImplementedError
    end

    def type_table
      raise NotImplementedError
    end

    def set_attribute_groups_for_type(type)
      type_data = type_data_for(type)
      return unless type_data && type_data['form_configuration']

      type_data['form_configuration'].each do |form_config_attr|
        groups = type.default_attribute_groups
        query = seed_data.find_reference(form_config_attr['query'])
        query_association = "query_#{query.id}"
        groups.unshift([form_config_attr['group_name'], [query_association.to_sym]])

        type.attribute_groups = groups
      end

      type.save!
    end

    private

    def type_data_for(type)
      types_data = seed_data.lookup('type_configuration') || []
      types_data.find { |entry| I18n.t(entry['type']) == type.name }
    end
  end
end
