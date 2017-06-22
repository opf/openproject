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
  module Decorators
    module LinkedResource
      def self.included(base)
        base.extend ClassMethods
      end

      def self.prepended(base)
        base.extend ClassMethods
      end

      def to_hash(*)
        super.tap do |hash|
          links = {}
          representable_attrs.find_all do |dfn|
            next unless dfn[:linked_resource]
            name = dfn[:as] ? dfn[:as].(nil) : dfn.name
            fragment = hash.delete(name)
            next unless fragment
            links[name] = fragment
          end

          hash['_links'].merge!(links)
        end
      end

      def from_hash(hash, *)
        return super unless hash['_links']

        representable_attrs.find_all do |dfn|
          next unless dfn[:linked_resource]
          name = dfn[:as] ? dfn[:as].(nil) : dfn.name
          fragment = hash['_links'].delete(name)
          next unless fragment

          hash[name] = fragment
        end

        super
      end

      module ClassMethods
        def linked_resource(name,
                            getter:,
                            setter:,
                            show_if: ->(*) { true })

          property name,
                   exec_context: :decorator,
                   getter: getter,
                   setter: setter,
                   if: show_if,
                   linked_resource: true
        end
      end
    end
  end
end
