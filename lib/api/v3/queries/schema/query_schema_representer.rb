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
    module Queries
      module Schema
        class QuerySchemaRepresenter < ::API::Decorators::SchemaRepresenter
          class << self
            def represented_class
              Query
            end
          end

          def initialize(schema, context)
            @self_link = context.delete(:self_link) || nil
            super(schema, context)
          end

          link :self do
            { href: @self_link } if @self_link
          end

          schema :id,
                 type: 'Integer'

          schema :name,
                 type: 'String',
                 min_length: 1,
                 max_length: 255

          schema :filters,
                 type: 'Object'

          schema :column_names,
                 type: 'String[]'

          schema :sort_criteria,
                 type: 'Object'

          schema :group_by,
                 type: 'String',
                 required: false

          schema :display_sums,
                 type: 'Boolean'

          schema :is_public,
                 type: 'Boolean'

          schema :is_starred,
                 type: 'Boolean'
        end
      end
    end
  end
end
