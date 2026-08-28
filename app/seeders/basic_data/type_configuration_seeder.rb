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

    def seed_data!
      seed_data.each("type_configuration") do |type_configuration_data|
        variant = seed_data.find_reference(type_configuration_data["type"]).default_variant
        groups = form_groups(type_configuration_data)
        groups = merge_with_default_groups(groups, variant) if merge_form_configuration?(type_configuration_data)
        variant.update(attribute_groups: groups)
      end
    end

    # The queries embedded into the form configuration are seeded by the GlobalQuerySeeder within
    # the same run. When re-seeding an installation whose global queries still exist (but whose
    # projects were deleted), that seeder is skipped and the references are not registered again.
    # The seeder is then not applicable: we cannot re-apply the form configuration, but that is
    # acceptable as the base variants created in the initial seeding already carry it.
    def all_required_references
      references = []
      seed_data.each("type_configuration") do |type_configuration_data|
        Array(type_configuration_data["form_configuration"]).each do |form_config_attr|
          references << form_config_attr["query"] if form_config_attr["query"]
        end
      end
      references
    end

    private

    # Whether the form configuration defined in the seed data should be merged with the
    # variant's default form configuration as defined in the Ruby code. Defaults to false,
    # in which case only the groups from the seed data make up the form configuration.
    def merge_form_configuration?(type_configuration_data)
      ActiveModel::Type::Boolean.new.cast(type_configuration_data["merge_form_configuration"])
    end

    def form_groups(type_configuration_data)
      type_configuration_data["form_configuration"].map do |form_config_attr|
        if form_config_attr["query"]
          query = seed_data.find_reference(form_config_attr["query"])
          query_association = "query_#{query.id}"
          [form_config_attr["group_name"], [query_association.to_sym]]
        else
          [form_config_attr["group_name"], Array(form_config_attr["attributes"]).map(&:to_s)]
        end
      end
    end

    def merge_with_default_groups(groups, variant)
      default_groups = variant.default_attribute_groups
      default_keys = default_groups.map(&:first)

      merged_defaults = default_groups.map do |key, members|
        seeded = groups.find { |seeded_key, *| seeded_key == key }
        seeded ? [key, members + seeded[1]] : [key, members]
      end

      groups.reject { |key, *| default_keys.include?(key) } + merged_defaults
    end
  end
end
