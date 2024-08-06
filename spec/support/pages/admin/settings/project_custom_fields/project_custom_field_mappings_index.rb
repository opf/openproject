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

require "support/pages/projects/index"

module Pages
  module Admin
    module Settings
      module ProjectCustomFields
        class ProjectCustomFieldMappingsIndex < ::Pages::Projects::Index
          def path
            "/admin/settings/project_custom_fields/#{project_custom_field.id}/project_mappings"
          end

          def within_row(project)
            row = page.find("#settings-project-custom-fields-project-custom-field-mapping-row-component-project-#{project.id}")
            row.hover
            within row do
              yield row
            end
          end
        end
      end
    end
  end
end
