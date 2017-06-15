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
            title: represented.from.subject
          }
        end

        link :to do
          {
            href: api_v3_paths.work_package(represented.to_id),
            title: represented.to.subject
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

        property :id

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
                 if: -> (*) {
                   # the relation type may be blank when parsing for an update
                   relation_type == "precedes" || relation_type.blank?
                 }

        property :description, render_nil: true

        property :from, embedded: true, exec_context: :decorator, if: -> (*) { embed_links }
        property :to, embedded: true, exec_context: :decorator, if: -> (*) { embed_links }

        ##
        # Used while parsing JSON to initialize `from` and `to` through the given links.
        def initialize_embedded_links!(data)
          from_id = parse_wp_id data, "from"
          to_id = parse_wp_id data, "to"

          represented.from_id = from_id if from_id
          represented.to_id = to_id if to_id
        end

        ##
        # Overrides Roar::JSON::HAL::Resources#from_hash
        def from_hash(hash, *)
          if hash["_links"]
            initialize_embedded_links! hash
          end

          super
        end

        def parse_wp_id(data, link_name)
          value = data.dig("_links", link_name, "href")

          if value
            ::API::Utilities::ResourceLinkParser.parse_id(
              value,
              property: :from,
              expected_version: "3",
              expected_namespace: "work_packages"
            )
          end
        end

        def _type
          @_type ||= "Relation"
        end

        def _type=(_type)
          # readonly
        end

        def name
          I18n.t "label_#{represented.relation_type}"
        end

        def name=(name)
          # readonly
        end

        def reverse_type
          Relation::TYPES[represented.relation_type][:sym]
        end

        def reverse_type=(reverse_type)
          # readonly
        end

        def manage_relations?
          current_user_allowed_to :manage_work_package_relations, context: represented.from.project
        end

        def from
          represent_work_package(represented.from)
        end

        def to
          represent_work_package(represented.to)
        end

        def represent_work_package(wp)
          ::API::V3::WorkPackages::WorkPackageRepresenter.create(
            wp,
            current_user: current_user,
            embed_links: false
          )
        end

        self.to_eager_load = [:to,
                              from: { project: :enabled_modules }]
      end
    end
  end
end
