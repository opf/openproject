# --copyright
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
# ++

module API
  module Decorators
    module SelfLink
      def self.included(base)
        base.extend ClassMethods
      end

      def self.prepended(base)
        base.extend ClassMethods
      end

      def self_v3_path(path, id_attribute)
        path ||= _type.underscore

        id = if id_attribute.respond_to?(:call)
               instance_eval(&id_attribute)
             else
               represented.send(id_attribute)
             end

        id = [nil] if id.nil?

        api_v3_paths.send(path, *Array(id))
      end

      module ClassMethods
        def self_link(path: nil,
                      id_attribute: :id,
                      title: true,
                      title_getter: ->(*) { represented.name },
                      **options)

          self_config = { rel: :self }.merge(options)

          link self_config do
            self_path = self_v3_path(path, id_attribute)

            link_object = { href: self_path }
            if title
              title_string = instance_eval(&title_getter)
              link_object[:title] = title_string if title_string
            end

            link_object
          end
        end
      end
    end
  end
end
