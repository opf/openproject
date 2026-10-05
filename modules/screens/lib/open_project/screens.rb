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
  module Screens
    require "open_project/screens/engine"

    CORE_DEPENDENCIES = {
      "TypeVariant.all_work_package_form_attributes" => -> { TypeVariant.respond_to?(:all_work_package_form_attributes) },
      "TypeVariant.translated_work_package_form_attributes" => -> { TypeVariant.respond_to?(:translated_work_package_form_attributes) },
      "TypeVariant#required_attributes" => -> { TypeVariant.method_defined?(:required_attributes) },
      "TypeVariant#passes_attribute_constraint?" => -> { TypeVariant.method_defined?(:passes_attribute_constraint?) },
      "Project#type_variant" => -> { Project.method_defined?(:type_variant) },
      "Project#type_variants" => -> { Project.method_defined?(:type_variants) }
    }.freeze

    def self.assert_core_dependencies!
      missing = CORE_DEPENDENCIES.filter_map { |name, check| name unless check.call }
      return if missing.empty?

      raise "openproject-screens depends on core methods that are missing: #{missing.join(', ')}"
    end
  end
end
