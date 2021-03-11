#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# TODO: Copied from principal_representer_factory. See to reducing duplication
module API
  module V3
    module Capabilities
      class ContextRepresenterFactory
        ##
        # Create the appropriate subclass representer
        # for each principal entity
        def self.create(model, **args)
          representer_class(model)
            .create(model, **args)
        end

        def self.representer_class(model)
          case model
          when Project
            ::API::V3::Projects::ProjectRepresenter
          when NilClass
            ::API::V3::Capabilities::Contexts::GlobalRepresenter
          else
            raise ArgumentError, "Missing concrete context representer for #{model}"
          end
        end

        def self.create_link_lambda(name, getter: "#{name}_id")
          ->(*) {
            case represented.send(name)
            when NilClass
              {
                href: api_v3_paths.capabilities_contexts_global
              }
            when Project
              instance_exec(&self.class.associated_resource_default_link(name,
                                                                         v3_path: :project,
                                                                         skip_link: -> { false },
                                                                         title_attribute: :name,
                                                                         getter: getter))
            else
              raise "undefined link generation for #{instance}"
            end
          }
        end

        def self.create_getter_lambda(name)
          ->(*) {
            next unless embed_links

            instance = represented.send(name)
            next if instance.nil?

            ::API::V3::Capabilities::ContextRepresenterFactory
              .create(represented.send(name), current_user: current_user)
          }
        end
      end
    end
  end
end
