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

module API
  module V3
    module Utilities
      class CustomFieldSumInjector < CustomFieldInjector
        def inject_schema(custom_field, _options = {})
          inject_basic_schema(custom_field)
        end

        def inject_basic_schema(custom_field, _options = {})
          @class.schema property_name(custom_field),
                        type: TYPE_MAP[custom_field.field_format],
                        name_source: ->(*) { custom_field.name },
                        required: false,
                        writable: false,
                        show_if: ->(*) { custom_field.summable? }
        end

        def inject_property_value(custom_field, _options = {})
          @class.property property_name(custom_field),
                          getter: property_value_getter_for(custom_field),
                          setter: property_value_setter_for(custom_field),
                          render_nil: true,
                          if: ->(*) { custom_field.summable? }
        end
      end
    end
  end
end
