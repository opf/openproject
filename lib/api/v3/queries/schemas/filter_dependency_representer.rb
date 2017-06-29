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
      module Schemas
        class FilterDependencyRepresenter < ::API::Decorators::SchemaRepresenter
          include API::Utilities::RepresenterToJsonCache

          def initialize(filter, operator, form_embedded: false)
            self.operator = operator

            super(filter, current_user: nil, form_embedded: form_embedded)
          end

          schema_with_allowed_link :values,
                                   type: ->(*) { type },
                                   writable: true,
                                   has_default: false,
                                   required: true,
                                   visibility: false,
                                   href_callback: ->(*) {
                                     href_callback
                                   },
                                   show_if: ->(*) {
                                     value_required?
                                   }

          property :_dependencies,
                   if: false,
                   exec_context: :decorator

          def _type; end

          # While this is not actually the represented class,
          # this is what the superclass expects in order to have the
          # right i18n
          def self.represented_class
            Query
          end

          # Avoid having a _links section on the json objects
          def to_hash(*)
            super.tap do |hash|
              hash.delete('_links')
            end
          end

          def json_cache_key
            [operator.to_sym, I18n.locale]
          end

          private

          def value_required?
            operator.requires_value?
          end

          def type
            raise NotImplementedError, 'Subclass has to implement #type'
          end

          def href_callback
            raise NotImplementedError, 'Subclass has to implement #href_callback'
          end

          attr_accessor :operator

          alias :filter :represented
        end
      end
    end
  end
end
