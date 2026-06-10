# frozen_string_literal: true

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
    module LinkedResource
      def self.included(base)
        base.extend ClassMethods
      end

      def self.prepended(base)
        base.extend ClassMethods
      end

      def from_hash(hash, *)
        return super unless hash && hash["_links"]

        validate_links!(hash["_links"])

        copied_hash = hash.deep_dup

        representable_attrs.find_all do |dfn|
          next unless dfn[:linked_resource]

          name = dfn[:as] ? dfn[:as].(nil) : dfn.name
          fragment = copied_hash["_links"].delete(name)
          next unless fragment

          copied_hash[name] = fragment
        end

        super(copied_hash, *)
      end

      private

      def parse_link_ids_from_fragment(fragment, path)
        struct = Struct.new(:id).new
        link = ::API::Decorators::LinkObject.new(struct, path: path, property_name: :id, setter: "id=")

        fragment.map do |href|
          link.from_hash(href)
          struct.id
        end
      end

      def validate_links!(links)
        raise ::API::Errors::BadRequest.new(I18n.t("api_v3.errors.bad_request.links_not_an_object")) unless links.is_a?(Hash)

        invalid, = links.find { |_, link| !(link.is_a?(Hash) || link.is_a?(Array)) }
        return if invalid.nil?

        raise ::API::Errors::BadRequest.new(I18n.t("api_v3.errors.bad_request.invalid_link", key: invalid))
      end

      def associated_resource_default_link(represented,
                                           name,
                                           v3_path:,
                                           skip_link:,
                                           title_attribute:,
                                           getter: :"#{name}_id",
                                           undisclosed: false)
        if undisclosed && instance_exec(&skip_link)
          {
            href: API::V3::URN_UNDISCLOSED,
            title: I18n.t(:"api_v3.undisclosed.#{name}")
          }
        elsif !instance_exec(&skip_link)
          ::API::Decorators::LinkObject
            .new(represented,
                 path: v3_path.is_a?(Proc) ? instance_exec(&v3_path) : v3_path,
                 property_name: name,
                 title_attribute:,
                 getter:)
            .to_hash
        end
      end

      module ClassMethods
        def resource(name,
                     getter:,
                     setter:,
                     link:,
                     uncacheable_link: false,
                     link_cache_if: nil,
                     show_if: ->(*) { true },
                     skip_render: nil,
                     embedded: true)
          link(link_attr(name, uncacheable_link, link_cache_if), &link)

          property name,
                   exec_context: :decorator,
                   getter:,
                   setter:,
                   if: show_if,
                   skip_render: ->(*) { !embed_links || (skip_render && instance_exec(&skip_render)) },
                   linked_resource: true,
                   embedded:,
                   uncacheable: true
        end

        def resources(name,
                      getter:,
                      setter:,
                      link:,
                      uncacheable_link: false,
                      link_cache_if: nil,
                      show_if: ->(*) { true },
                      skip_render: nil,
                      embedded: true)
          links(link_attr(name, uncacheable_link, link_cache_if), &link)

          property name,
                   exec_context: :decorator,
                   getter:,
                   setter:,
                   if: show_if,
                   skip_render: ->(*) { !embed_links || (skip_render && instance_exec(&skip_render)) },
                   linked_resource: true,
                   embedded:,
                   uncacheable: true
        end

        def resource_link(name,
                          setter:,
                          getter:,
                          show_if: ->(*) { true })
          resource(name,
                   getter: ->(*) {},
                   setter:,
                   link: getter,
                   show_if:,
                   embedded: false)
        end

        # Includes _link and _embedded elements into the HAL representer for
        # resources that are connected to the current resource via a belongs_to association, e.g.
        # WorkPackage -> belongs_to -> project.
        #
        # @param skip_render [optional, Proc] If the proc returns true, neither _link nor _embedded of the resource will be rendered.
        # @param undisclosed [optional, true, false] If true, instead of not rendering the resource upon `skip_render`, an { "href": "urn:openproject-org:api:v3:undisclosed" } link will be rendered. This can be used e.g. when the parent of a project is invisible to the user and the existence, if not the actual parent, is to be communicated. The resource is still not embedded in this case.
        def associated_resource(name,
                                as: nil,
                                representer: nil,
                                v3_path: name,
                                skip_render: ->(*) { false },
                                skip_link: skip_render,
                                undisclosed: false,
                                link_title_attribute: :name,
                                link_getter: :"#{name}_id",
                                link_property_name: nil,
                                uncacheable_link: false,
                                getter: associated_resource_default_getter(name, representer),
                                setter: associated_resource_default_setter(name, as, v3_path),
                                link: associated_resource_default_link_lambda(link_property_name || name,
                                                                              v3_path:,
                                                                              skip_link:,
                                                                              undisclosed:,
                                                                              title_attribute: link_title_attribute,
                                                                              getter: link_getter))
          resource(as || name,
                   getter:,
                   setter:,
                   link:,
                   uncacheable_link:,
                   skip_render:)
        end

        # Like associated_resource, but skips rendering and shows an undisclosed
        # link when the associated record exists but is not visible to the current user.
        # Requires the associated model to implement +visible?(user)+.
        def associated_visible_resource(name,
                                        as: nil,
                                        representer: nil,
                                        v3_path: name,
                                        link_title_attribute: :name,
                                        undisclosed_title: :"api_v3.undisclosed.#{name.to_s.camelize(:lower)}")
          associated_resource(
            name,
            as:,
            representer:,
            v3_path:,
            skip_render: ->(*) {
              represented.public_send(:"#{name}_id").nil? ||
                !represented.public_send(name)&.visible?(current_user)
            },
            link: associated_visible_resource_link_lambda(name,
                                                          v3_path:,
                                                          link_title_attribute:,
                                                          undisclosed_title:)
          )
        end

        def associated_visible_resource_link_lambda(name, v3_path:, link_title_attribute:, undisclosed_title:)
          ->(*) do
            id = represented.public_send(:"#{name}_id")
            next if id.nil?

            resource = represented.public_send(name)
            if resource&.visible?(current_user)
              { href: api_v3_paths.public_send(v3_path, id),
                title: resource.public_send(link_title_attribute) }
            else
              { href: ::API::V3::URN_UNDISCLOSED,
                title: I18n.t(undisclosed_title) }
            end
          end
        end

        def link_attr(name, uncacheable, link_cache_if)
          links_attr = { rel: name.to_s.camelize(:lower) }
          links_attr[:uncacheable] = true if uncacheable
          links_attr[:cache_if] = link_cache_if if link_cache_if

          links_attr
        end

        def associated_resource_default_getter(name,
                                               representer)
          representer ||= default_representer(name)

          ->(*) do
            if embed_links && represented.send(name)
              representer.create(represented.send(name), current_user:)
            end
          end
        end

        def associated_resource_default_setter(name, as, v3_path)
          ->(fragment:, **) do
            link = ::API::Decorators::LinkObject.new(represented,
                                                     path: v3_path,
                                                     property_name: as || name,
                                                     getter: :"#{name}_id",
                                                     setter: :"#{name}_id=")

            link.from_hash(fragment)
          end
        end

        def associated_resource_default_link_lambda(name,
                                                    v3_path:,
                                                    skip_link:,
                                                    title_attribute:,
                                                    getter: :"#{name}_id",
                                                    undisclosed: false)
          ->(*) do
            associated_resource_default_link(represented,
                                             name,
                                             v3_path:,
                                             skip_link:,
                                             title_attribute:,
                                             getter:,
                                             undisclosed:)
          end
        end

        def associated_resources(name,
                                 as: name,
                                 representer: nil,
                                 v3_path: name.to_s.singularize.to_sym,
                                 skip_render: ->(*) { false },
                                 skip_link: skip_render,
                                 link_title_attribute: :name,
                                 uncacheable_link: false,
                                 getter: associated_resources_default_getter(name, representer),
                                 setter: associated_resources_default_setter(name, v3_path),
                                 link: associated_resources_default_link(name,
                                                                         v3_path:,
                                                                         skip_link:,
                                                                         title_attribute: link_title_attribute))
          resources(as,
                    getter:,
                    setter:,
                    link:,
                    uncacheable_link:,
                    skip_render:)
        end

        def associated_resources_default_getter(name,
                                                representer)
          representer ||= default_representer(name.to_s.singularize)

          ->(*) do
            represented.send(name)&.map do |associated|
              representer.create(associated, current_user:)
            end
          end
        end

        def associated_resources_default_setter(name, v3_path)
          ->(fragment:, **) do
            ids = parse_link_ids_from_fragment(fragment, v3_path)
            represented.send(:"#{name.to_s.singularize}_ids=", ids)
          end
        end

        def associated_resources_default_link(name,
                                              v3_path:,
                                              skip_link:,
                                              title_attribute:)
          ->(*) do
            next if instance_exec(&skip_link)

            represented.send(name).map do |associated|
              ::API::Decorators::LinkObject
                .new(associated,
                     property_name: :itself,
                     path: v3_path,
                     getter: :id,
                     title_attribute:)
                .to_hash
            end
          end
        end

        def default_representer(name)
          "::API::V3::#{name.to_s.pluralize.camelize}::#{name.to_s.camelize}Representer".constantize
        end
      end
    end
  end
end
