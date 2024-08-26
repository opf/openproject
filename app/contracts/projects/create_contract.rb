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

module Projects
  class CreateContract < BaseContract
    include AdminWritableTimestamps
    # Projects update their updated_at timestamp due to awesome_nested_set
    # so allowing writing here would be useless.
    allow_writable_timestamps :created_at

    def writable_attributes
      if allowed_to_write_custom_fields?
        super
      else
        without_custom_fields(super)
      end
    end

    protected

    def collect_available_custom_field_attributes
      model.all_visible_custom_fields.map(&:attribute_name)
    end

    private

    def allowed_to_write_custom_fields?
      # Writable attributes are already restricted based on their visibility in the
      # ProjectCustomField.visible scope. Here it is enough to check whether the user
      # has permission to copy_projects or edit_project_attributes in any project.
      user.admin? ||
      user.allowed_globally?(:add_project) ||
      (model.parent && user.allowed_in_project?(:add_subprojects, model.parent)) ||
      user.allowed_in_any_project?(:copy_projects) ||
      user.allowed_in_any_project?(:edit_project_attributes)
    end

    def without_custom_fields(changes) = changes.grep_v(/^custom_field_/)

    def validate_user_allowed_to_manage
      unless user.allowed_globally?(:add_project) ||
             (model.parent && user.allowed_in_project?(:add_subprojects, model.parent))

        errors.add :base, :error_unauthorized
      end
    end
  end
end
