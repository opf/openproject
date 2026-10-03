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

# frozen_string_literal: true

module OpenProject
  module FieldRules
    require "open_project/field_rules/engine"

    PATCH_TARGETS = {
      "WorkPackages::BaseContract" => %i[writable_attributes validate_enabled_type],
      "WorkPackages::SetAttributesService" => %i[set_calculated_attributes assign_default_type],
      "API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter" => %i[to_json]
    }.freeze

    def self.assert_patch_targets!
      PATCH_TARGETS.each do |class_name, methods|
        klass = class_name.constantize
        missing = methods.reject { |name| klass.method_defined?(name) || klass.private_method_defined?(name) }
        next if missing.empty?

        raise "openproject-field_rules patches #{class_name}##{missing.join(', #')}, which core no longer defines"
      end
      raise "openproject-field_rules needs TypeVariant.add_constraint" unless TypeVariant.respond_to?(:add_constraint)
    end
  end
end
