# frozen_string_literal: true

# -- copyright
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
  module V3
    module Workspaces
      module LinkedResource
        extend ActiveSupport::Concern
        include API::Decorators::LinkedResource

        def project_link(project, name:, getter: "#{name}_id")
          if project_invisible?(project)
            {
              href: API::V3::URN_UNDISCLOSED,
              title: I18n.t(:"api_v3.undisclosed.#{name}")
            }
          elsif !project
            {
              href: nil
            }
          else
            associated_resource_default_link(project,
                                             :itself,
                                             v3_path: project.workspace_type,
                                             skip_link: -> { false },
                                             title_attribute: :name,
                                             getter:)
          end
        end

        def project_invisible?(project)
          # Explicitly check for admin as an archived project
          # will lead to the admin losing permissions in the project.
          project && !project.visible? && !current_user&.admin?
        end

        class_methods do
          def associated_project(name = :project,
                                 as: name,
                                 skip_render: ->(*) { project_invisible?(represented.public_send(name)) })
            options = {
              as:,
              representer: ::API::V3::Projects::ProjectRepresenter,
              skip_render:,
              link: ::API::V3::Workspaces::WorkspaceRepresenterFactory
                     .create_link_lambda(name, property_name: as),
              setter: ::API::V3::Workspaces::WorkspaceRepresenterFactory
                      .create_setter_lambda(name)
            }

            if include?(API::Caching::CachedRepresenter)
              # Prevent this option to be displayed in the generated JSON.
              # A cached representer will remove this option anyway but uncached representers do not.
              options[:uncacheable_link] = true
            end

            associated_resource(name,
                                **options)
          end
        end
      end
    end
  end
end
