#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module API
  module V3
    module Queries
      module Schemas
        class CustomOptionFilterDependencyRepresenter <
          FilterDependencyRepresenter

          schema_with_allowed_collection :values,
                                         type: ->(*) { type },
                                         writable: true,
                                         has_default: false,
                                         required: true,
                                         values_callback: ->(*) {
                                           represented.custom_field.custom_options
                                         },
                                         value_representer: CustomOptions::CustomOptionRepresenter,
                                         link_factory: ->(value) {
                                           {
                                             href: api_v3_paths.custom_option(value.id),
                                             title: value.to_s
                                           }
                                         },
                                         show_if: ->(*) {
                                           value_required?
                                         }

          private

          def type
            '[]CustomOption'
          end
        end
      end
    end
  end
end
