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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSumsSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

          custom_field_injector(type: :schema_representer,
                                injector_class: ::API::V3::Utilities::CustomFieldSumInjector)

          class << self
            def represented_class
              WorkPackage
            end
          end

          link :self do
            { href: api_v3_paths.work_package_sums_schema }
          end

          schema :estimated_time,
                 type: "Duration",
                 required: false,
                 writable: false

          schema :story_points,
                 type: "Integer",
                 required: false

          schema :remaining_time,
                 type: "Duration",
                 name_source: :remaining_hours,
                 required: false,
                 writable: false

          schema :overall_costs,
                 type: "String",
                 required: false,
                 writable: false

          schema :labor_costs,
                 type: "String",
                 required: false,
                 writable: false

          schema :material_costs,
                 type: "String",
                 required: false,
                 writable: false
        end
      end
    end
  end
end
