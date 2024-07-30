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

module Admin
  module Settings
    module ProjectCustomFields
      module ComponentStreams
        extend ActiveSupport::Concern

        included do
          def update_header_via_turbo_stream
            update_via_turbo_stream(
              component: ::Settings::ProjectCustomFields::HeaderComponent.new
            )
          end

          def update_section_via_turbo_stream(project_custom_field_section:)
            update_via_turbo_stream(
              component: ::Settings::ProjectCustomFieldSections::ShowComponent.new(
                # Note: `first_and_last:` argument is not necessary here, because we render
                # a single custom field section, and not a list of sections. Calling first?
                # and last? method in the component will not result in an N+1 in this case.
                project_custom_field_section:
              )
            )
          end

          def update_section_dialog_body_form_via_turbo_stream(project_custom_field_section:)
            update_via_turbo_stream(
              component: ::Settings::ProjectCustomFieldSections::DialogBodyFormComponent.new(
                project_custom_field_section:
              )
            )
          end

          def update_sections_via_turbo_stream(project_custom_field_sections:)
            replace_via_turbo_stream(
              component: ::Settings::ProjectCustomFieldSections::IndexComponent.new(
                project_custom_field_sections:
              )
            )
          end
        end
      end
    end
  end
end
