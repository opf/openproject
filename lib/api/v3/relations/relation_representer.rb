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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Relations
      class RelationRepresenter < ::API::Decorators::Single
        link :self do
          { href: api_v3_paths.relation(represented.id) }
        end

        link :relatedFrom do
          { href: api_v3_paths.work_package(represented.from_id) }
        end

        link :relatedTo do
          { href: api_v3_paths.work_package(represented.to_id) }
        end

        link :remove do
          {
            href: api_v3_paths.work_package_relation(represented.id, represented.from.id),
            method: :delete,
            title: 'Remove relation'
          } if current_user_allowed_to(:manage_work_package_relations,
                                       context: represented.from.project)
        end

        property :delay, render_nil: true, if: -> (*) { relation_type == 'precedes' }

        def _type
          "Relation::#{relation_type}"
        end

        private

        def relation_type
          represented.relation_type_for(work_package).camelize
        end

        def work_package
          context[:work_package]
        end

        def current_user
          context[:current_user]
        end
      end
    end
  end
end
