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
    module Projects
      module Copy
        class ProjectCopySchemaRepresenter < ::API::V3::Projects::Schemas::ProjectSchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
          custom_field_injector type: :schema_representer

          ::Projects::CopyService.copyable_dependencies.each do |dep|
            identifier = dep[:identifier]
            name_source = dep[:name_source]

            schema :"copy_#{identifier}",
                   type: "Boolean",
                   name_source:,
                   has_default: true,
                   writable: true,
                   required: false,
                   description: -> do
                     count = dep[:count_source].call(represented.model, current_user)

                     I18n.t("copy_project.x_objects_of_this_type", count: count.to_i)
                   end,
                   location: :meta
          end

          schema :send_notifications,
                 type: "Boolean",
                 name_source: ->(*) { I18n.t(:label_project_copy_notifications) },
                 has_default: true,
                 writable: true,
                 required: false,
                 location: :meta
        end
      end
    end
  end
end
