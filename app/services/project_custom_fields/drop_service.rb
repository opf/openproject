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

module ProjectCustomFields
  class DropService < ::BaseServices::BaseCallable
    def initialize(user:, project_custom_field:)
      super()
      @user = user
      @project_custom_field = project_custom_field
    end

    def perform(params)
      service_call = validate_permissions
      service_call = perform_drop(service_call, params) if service_call.success?

      service_call
    end

    def validate_permissions
      if @user.admin?
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_drop(service_call, params)
      begin
        section_changed, current_section, old_section = check_and_update_section_if_changed(params)
        update_position(params[:position]&.to_i)

        service_call.success = true
        service_call.result = { section_changed:, current_section:, old_section: }
      rescue StandardError => e
        service_call.success = false
        service_call.errors = e.message
      end

      service_call
    end

    private

    def check_and_update_section_if_changed(params)
      current_section = @project_custom_field.project_custom_field_section
      new_section_id = params[:target_id]&.to_i

      if current_section.id != new_section_id
        old_section = current_section
        current_section = update_section(new_section_id)
        return [true, current_section, old_section]
      end

      [false, current_section, nil]
    end

    def update_section(new_section_id)
      current_section = ProjectCustomFieldSection.find(new_section_id)
      @project_custom_field.remove_from_list
      @project_custom_field.update(project_custom_field_section: current_section)
      current_section
    end

    def update_position(new_position)
      @project_custom_field.insert_at(new_position)
    end
  end
end
