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

        link :from do
          {
            href: api_v3_paths.work_package(represented.from_id),
            title: "Show work package"
          }
        end

        link :to do
          {
            href: api_v3_paths.work_package(represented.to_id),
            title: "Show work package"
          }
        end

        link :updateImmediately do
          if manage_relations?
            { href: api_v3_paths.relation(represented.id), method: :patch }
          end
        end

        link :delete do
          if manage_relations?
            {
              href: api_v3_paths.relation(represented.id),
              method: :delete,
              title: 'Remove relation'
            }
          end
        end

        property :name, exec_context: :decorator

        property :relation_type, as: :type

        property :reverse_type, as: :reverseType, exec_context: :decorator

        ##
        # The `delay` property is only used for the relation type "precedes".
        # Consequently it also makes sense with its reverse "follows".
        # However, relations will always be saved as "precedes" with the reverse of "follows".
        # See `Relation#update_schedule` and `Relation#reverse_if_needed` which are both
        # run before saving any relation.
        property :delay,
                 render_nil: true,
                 if: -> (*) { relation_type == "precedes" }

        property :description, render_nil: true

        def _type
          "Relation"
        end

        def name
          I18n.t "label_#{represented.relation_type}"
        end

        def reverse_type
          Relation::TYPES[represented.relation_type][:sym]
        end

        def manage_relations?
          current_user_allowed_to :manage_work_package_relations, context: represented.from.project
        end
      end
    end
  end
end
