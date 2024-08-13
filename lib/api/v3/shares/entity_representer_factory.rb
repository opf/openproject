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
  module V3
    module Shares
      module EntityRepresenterFactory
        module_function

        ##
        # Create the appropriate subclass representer
        # for each principal entity
        def create(model, **args)
          representer_class(model).create(model, **args)
        end

        def representer_class(model)
          case model
          when WorkPackage
            ::API::V3::WorkPackages::WorkPackageRepresenter
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def representer_type(model)
          case model
          when WorkPackage then :work_package
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def title_attribute(model)
          case model
          when WorkPackage then :subject
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def create_link_lambda(name, getter: "#{name}_id")
          ->(*) {
            v3_path = API::V3::Shares::EntityRepresenterFactory.representer_type(represented.send(name))
            title_attribute = API::V3::Shares::EntityRepresenterFactory.title_attribute(represented.send(name))

            instance_exec(&self.class.associated_resource_default_link(name,
                                                                       v3_path:,
                                                                       skip_link: -> { false },
                                                                       title_attribute:,
                                                                       getter:))
          }
        end

        def create_getter_lambda(name)
          ->(*) {
            next unless embed_links

            instance = represented.send(name)
            next if instance.nil?

            ::API::V3::Shares::EntityRepresenterFactory.create(instance, current_user:)
          }
        end
      end
    end
  end
end
