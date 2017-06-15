#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Queries
      module Filters
        class QueryFilterInstanceRepresenter < ::API::Decorators::Single
          def initialize(model)
            super(model, current_user: nil, embed_links: true)
          end

          property :linked_resources,
                   as: :_links,
                   exec_context: :decorator,
                   getter: ->(*) {
                     query_filter_instance_links_representer represented
                   },
                   setter: ->(value, *) {
                     representer = query_filter_instance_links_representer represented
                     representer.from_json(value.to_json)
                   }

          property :name,
                   exec_context: :decorator,
                   writeable: false

          property :values,
                   if: ->(*) { !represented.ar_object_filter? },
                   exec_context: :decorator,
                   show_nil: true

          private

          def name
            represented.human_name
          end

          def values
            if represented.respond_to?(:custom_field) &&
               represented.custom_field.field_format == 'bool'
              represented.values.map do |value|
                if value == CustomValue::BoolStrategy::DB_VALUE_TRUE
                  true
                else
                  false
                end
              end
            else
              represented.values
            end
          end

          def values=(vals)
            represented.values = if represented.respond_to?(:custom_field) &&
                                    represented.custom_field.field_format == 'bool'
                                   vals.map do |value|
                                     if value
                                       CustomValue::BoolStrategy::DB_VALUE_TRUE
                                     else
                                       CustomValue::BoolStrategy::DB_VALUE_FALSE
                                     end
                                   end
                                 else
                                   vals
                                 end
          end

          def _type
            "#{converted_name.camelize}QueryFilter"
          end

          def converted_name
            ::API::Utilities::PropertyNameConverter.from_ar_name(represented.name)
          end

          def query_filter_instance_links_representer(represented)
            ::API::V3::Queries::Filters::QueryFilterInstanceLinksRepresenter.new represented, current_user: current_user
          end
        end
      end
    end
  end
end
