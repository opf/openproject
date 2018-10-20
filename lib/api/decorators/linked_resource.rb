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

module API
  module Decorators
    module LinkedResource
      def self.included(base)
        base.extend ClassMethods
      end

      def self.prepended(base)
        base.extend ClassMethods
      end

      def from_hash(hash, *args)
        return super unless hash['_links']

        copied_hash = hash.deep_dup

        representable_attrs.find_all do |dfn|
          next unless dfn[:linked_resource]
          name = dfn[:as] ? dfn[:as].(nil) : dfn.name
          fragment = copied_hash['_links'].delete(name)
          next unless fragment

          copied_hash[name] = fragment
        end

        super(copied_hash, *args)
      end

      module ClassMethods
        def resource(name,
                     getter:,
                     setter:,
                     link:,
                     uncacheable_link: false,
                     show_if: ->(*) { true },
                     skip_render: nil,
                     embedded: true)

          link(link_attr(name, uncacheable_link), &link)

          property name,
                   exec_context: :decorator,
                   getter: getter,
                   setter: setter,
                   if: show_if,
                   skip_render: ->(*) { !embed_links || (skip_render && instance_exec(&skip_render)) },
                   linked_resource: true,
                   embedded: embedded,
                   uncacheable: true
        end

        def resources(name,
                      getter:,
                      setter:,
                      link:,
                      uncacheable_link: false,
                      show_if: ->(*) { true },
                      skip_render: nil,
                      embedded: true)

          links(link_attr(name, uncacheable_link), &link)

          property name,
                   exec_context: :decorator,
                   getter: getter,
                   setter: setter,
                   if: show_if,
                   skip_render: ->(*) { !embed_links || (skip_render && instance_exec(&skip_render)) },
                   linked_resource: true,
                   embedded: embedded,
                   uncacheable: true
        end

        def resource_link(name,
                          setter:,
                          getter:,
                          show_if: ->(*) { true })

          resource(name,
                   getter: ->(*) {},
                   setter: setter,
                   link: getter,
                   show_if: show_if,
                   embedded: false)
        end

        def associated_resource(name,
                                as: nil,
                                representer: nil,
                                v3_path: name,
                                skip_render: ->(*) { false },
                                skip_link: skip_render,
                                link_title_attribute: :name,
                                uncacheable_link: false,
                                getter: associated_resource_default_getter(name, representer),
                                setter: associated_resource_default_setter(name, as, v3_path),
                                link: associated_resource_default_link(name, v3_path, skip_link, link_title_attribute))

          resource((as || name),
                   getter: getter,
                   setter: setter,
                   link: link,
                   uncacheable_link: uncacheable_link,
                   skip_render: skip_render)
        end

        def link_attr(name, uncacheable)
          links_attr = { rel: name.to_s.camelize(:lower) }
          links_attr[:uncacheable] = true if uncacheable

          links_attr
        end

        def associated_resource_default_getter(name,
                                               representer)
          representer ||= default_representer(name)

          ->(*) do
            if embed_links && represented.send(name)
              representer.new(represented.send(name), current_user: current_user)
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

        def associated_resource_default_link(name, v3_path, skip_link, link_title_attribute)
          ->(*) do
            next if instance_exec(&skip_link)

            ::API::Decorators::LinkObject
              .new(represented,
                   path: v3_path,
                   property_name: name,
                   title_attribute: link_title_attribute)
              .to_hash
          end
        end

        def associated_resources(name,
                                 as: name,
                                 representer: nil,
                                 v3_path: name,
                                 skip_render: ->(*) { false },
                                 skip_link: skip_render,
                                 link_title_attribute: :name,
                                 getter: associated_resources_default_getter(name, representer),
                                 setter: associated_resources_default_setter(name, v3_path),
                                 link: associated_resources_default_link(name, v3_path, skip_link, link_title_attribute))

          resources(as,
                    getter: getter,
                    setter: setter,
                    link: link,
                    skip_render: skip_render)
        end

        def associated_resources_default_getter(name,
                                                representer)

          representer ||= default_representer(name.to_s.singularize)

          ->(*) do
            represented.send(name)&.map do |associated|
              representer.new(associated, current_user: current_user)
            end
          end
        end

        def associated_resources_default_setter(name, v3_path)
          ->(fragment:, **) do
            link = ::API::Decorators::LinkObject.new(represented,
                                                     path: v3_path,
                                                     property_name: name)

            link.from_hash(fragment)
          end
        end

        def associated_resources_default_link(name, v3_path, skip_link, link_title_attribute)
          ->(*) do
            next if instance_exec(&skip_link)

            represented.send(name).map do |associated|
              ::API::Decorators::LinkObject
                .new(represented,
                     path: v3_path,
                     property_name: associated.name,
                     title_attribute: link_title_attribute)
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
