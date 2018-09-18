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

Dir[File.dirname(__FILE__) + '/*.rb'].each { |file| require_dependency file }

module API
  module V3
    module Queries
      module Schemas
        module FilterDependencyRepresenterFactory
          def create(filter, operator, form_embedded: false)
            klass = representer_class(filter)

            klass.new(filter,
                      operator,
                      form_embedded: form_embedded)
          end

          private

          @specific_conversion = {
            'CreatedAtFilter': 'DateTimeFilter',
            'UpdatedAtFilter': 'DateTimeFilter',
            'AuthorFilter': 'UserFilter',
            'ResponsibleFilter': 'AllPrincipalsFilter',
            'AssignedToFilter': 'AllPrincipalsFilter',
            'WatcherFilter': 'UserFilter'
          }

          def representer_class(filter)
            name = filter_specific_representer_class(filter) ||
                   cf_representer_class(filter) ||
                   type_specific_representer_class(filter) ||
                   custom_representer_class(filter)

            name.constantize
          end

          def filter_specific_representer_class(filter)
            representer_name = "#{filter.class.to_s.demodulize}DependencyRepresenter"

            if API::V3::Queries::Schemas.const_defined?(representer_name)
              "API::V3::Queries::Schemas::#{representer_name}"
            end
          end

          def type_specific_representer_class(filter)
            representer_name = "#{filter.type.to_s.camelize}FilterDependencyRepresenter"

            if API::V3::Queries::Schemas.const_defined?(representer_name)
              "API::V3::Queries::Schemas::#{representer_name}"
            end
          end

          def cf_representer_class(filter)
            return unless filter.is_a?(::Queries::Filters::Shared::CustomFields::Base)

            format = filter.custom_field.field_format

            case format
            when 'list'
              'API::V3::Queries::Schemas::CustomOptionFilterDependencyRepresenter'
            when 'bool'
              'API::V3::Queries::Schemas::BooleanFilterDependencyRepresenter'
            when 'user', 'version', 'float'
              "API::V3::Queries::Schemas::#{format.camelize}FilterDependencyRepresenter"
            when 'string'
              'API::V3::Queries::Schemas::TextFilterDependencyRepresenter'
            end
          end

          def custom_representer_class(filter)
            if filter.respond_to? :dependency_class
              return filter.dependency_class
            end

            name = @specific_conversion[filter.class.to_s.demodulize.to_sym]
            if name.nil?
              raise ArgumentError,
                    "Filter #{filter.class} does not map to a dependency representer."
            end

            "API::V3::Queries::Schemas::#{name}DependencyRepresenter"
          end

          module_function :create,
                          :representer_class,
                          :filter_specific_representer_class,
                          :type_specific_representer_class,
                          :custom_representer_class,
                          :cf_representer_class
        end
      end
    end
  end
end
