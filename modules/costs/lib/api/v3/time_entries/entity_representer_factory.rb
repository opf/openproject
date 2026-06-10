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
  module V3
    module TimeEntries
      module EntityRepresenterFactory
        module_function

        ##
        # Create the appropriate subclass representer
        # for each Entity
        def create(model, **args)
          representer_class(model).create(model, **args)
        end

        def representer_class(model)
          return if model.nil?

          case model
          when WorkPackage then ::API::V3::WorkPackages::WorkPackageRepresenter
          when Meeting then ::API::V3::Meetings::MeetingRepresenter
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def representer_type(model)
          return if model.nil?

          case model
          when WorkPackage then :work_package
          when Meeting then :meeting
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def title_attribute(model)
          return if model.nil?

          case model
          when WorkPackage then :subject
          when Meeting then :title
          else
            raise ArgumentError, "Missing concrete entity representer for #{model}"
          end
        end

        def create_link_lambda(name, getter: "#{name}_id")
          ->(*) {
            entity = represented.send(name)
            v3_path = API::V3::TimeEntries::EntityRepresenterFactory.representer_type(entity)
            title_attribute = API::V3::TimeEntries::EntityRepresenterFactory.title_attribute(entity)

            link = instance_exec(&self.class.associated_resource_default_link_lambda(name,
                                                                                     v3_path:,
                                                                                     skip_link: -> { false },
                                                                                     title_attribute:,
                                                                                     getter:))

            entity.is_a?(WorkPackage) ? link.merge(displayId: entity.display_id.to_s) : link
          }
        end

        def create_getter_lambda(name)
          ->(*) {
            next unless embed_links

            instance = represented.send(name)
            next if instance.nil?

            ::API::V3::TimeEntries::EntityRepresenterFactory.create(instance, current_user:)
          }
        end

        def create_setter_lambda(name)
          ->(fragment:, **) {
            result = ::API::Utilities::ResourceLinkParser.parse(fragment["href"])

            case result[:namespace]
            when "meetings"
              represented.public_send("#{name}_id=", result[:id])
              represented.public_send("#{name}_type=", "Meeting")
            when "work_packages"
              represented.public_send("#{name}_id=", result[:id])
              represented.public_send("#{name}_type=", "WorkPackage")
            else
              # TODO: Handle error if unexpected object
            end
          }
        end
      end
    end
  end
end
