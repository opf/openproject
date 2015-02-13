#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Utilities
      class CustomFieldInjector
        TYPE_MAP = {
          'string' => 'String',
          'text' => 'Formattable',
          'int' => 'Integer',
          'float' => 'Float',
          'date' => 'Date',
          'bool' => 'Boolean',
          'user' => 'User',
          'version' => 'Version',
          'list' => 'StringObject'
        }

        def initialize(representer_class)
          @class = representer_class
        end

        def inject_schema(custom_field)
          # TODO: support allowed values for list, version and user
          @class.schema property_name(custom_field.id),
                        type: TYPE_MAP[custom_field.field_format],
                        title: custom_field.name,
                        required: custom_field.is_required,
                        writable: true
        end

        def inject_value(custom_field)
          # TODO: linked properties
          # TODO: 'text' as formattable
          @class.property property_name(custom_field.id),
                          getter: -> (*) {
                            self.custom_value_for(custom_field).value
                          },
                          setter: -> (value, *) {
                            self.custom_field_values = { custom_field.id => value }
                          }
        end

        private

        def property_name(id)
          "customField#{id}".to_sym
        end
      end
    end
  end
end
