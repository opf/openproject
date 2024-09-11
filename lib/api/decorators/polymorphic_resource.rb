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
  module Decorators
    module PolymorphicResource
      # Dynamically derive a linked resource from the given polymorphic resource
      def polymorphic_resource(name,
                               as: nil,
                               skip_render: ->(*) { false },
                               skip_link: skip_render,
                               uncacheable_link: false,
                               link_title_attribute: :name)

        resource((as || name),
                 getter: polymorphic_resource_getter(name),
                 setter: polymorphic_resource_setter(as),
                 link: polymorphic_link(name, link_title_attribute, skip_link),
                 uncacheable_link:,
                 skip_render:)
      end

      private

      def polymorphic_resource_getter(name)
        representer_fn = method(:polymorphic_resource_representer)
        ->(*) do
          next unless embed_links

          resource = represented.send(name)
          next if resource.nil?

          representer = representer_fn.call(resource)
          representer.create(resource, current_user:)
        end
      end

      def polymorphic_resource_setter(as)
        ->(fragment:, **) do
          name = represented.model_name.singular
          link = ::API::Decorators::LinkObject.new(represented,
                                                   path: name,
                                                   property_name: as || name,
                                                   getter: :"#{name}_id",
                                                   setter: :"#{name}_id=")

          link.from_hash(fragment)
        end
      end

      def polymorphic_link(name, title_attribute, skip_link)
        path_fn = method(:polymorphic_resource_path)

        ->(*) do
          next if instance_exec(&skip_link)

          resource = represented.send(name)
          next if resource.nil?

          path_name = path_fn.call(resource)

          ::API::Decorators::LinkObject
            .new(represented,
                 path: path_name,
                 property_name: name,
                 title_attribute:,
                 getter: :"#{name}_id")
            .to_hash
        end
      end

      def polymorphic_resource_representer(resource)
        mapped_representer(resource) || polymorphic_default_representer(resource.model_name)
      end

      def mapped_representer(resource)
        case resource
        when Journal
          ::API::V3::Activities::ActivityRepresenter
        end
      end

      def polymorphic_resource_path(resource)
        case resource
        when Journal
          :activity
        else
          resource.model_name.singular
        end
      end

      def polymorphic_default_representer(model_name)
        "::API::V3::#{model_name.plural.camelize}::#{model_name.singular.camelize}Representer".constantize
      end
    end
  end
end
