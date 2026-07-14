# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  class TypeConfigurationSeeder < Seeder
    self.needs = [
      BasicData::TypeSeeder
    ]

    def seed!
      seed_data.each("type_configuration") do |type_configuration_data|
        # The referenced queries are seeded by the GlobalQuerySeeder within the same run. When
        # re-seeding an installation whose global queries still exist (but whose projects were
        # deleted), that seeder is skipped and the references are not registered again. We then
        # cannot re-apply the form configuration, but that is acceptable: the types created in
        # the initial seeding already carry it.
        next unless queries_registered?(type_configuration_data)

        type = seed_data.find_reference(type_configuration_data["type"])
        groups = query_groups(type_configuration_data)
        groups += type.default_attribute_groups if merge_form_configuration?(type_configuration_data)
        type.update(attribute_groups: groups)
      end
    end

    private

    def queries_registered?(type_configuration_data)
      type_configuration_data["form_configuration"]
        .all? { |form_config_attr| seed_data.reference_exists?(form_config_attr["query"]) }
    end

    # Whether the form configuration defined in the seed data should be merged with the type's
    # default form configuration as defined in the Ruby code. Defaults to false, in which case
    # only the query groups from the seed data make up the form configuration.
    def merge_form_configuration?(type_configuration_data)
      ActiveModel::Type::Boolean.new.cast(type_configuration_data["merge_form_configuration"])
    end

    def query_groups(type_configuration_data)
      type_configuration_data["form_configuration"].map do |form_config_attr|
        query = seed_data.find_reference(form_config_attr["query"])
        query_association = "query_#{query.id}"
        [form_config_attr["group_name"], [query_association.to_sym]]
      end
    end
  end
end
