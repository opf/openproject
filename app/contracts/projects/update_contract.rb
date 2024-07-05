#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class UpdateContract < BaseContract
    private

    def unauthenticated_changed
      permissions = {
        edit_project_attributes: user.allowed_in_project?(:edit_project_attributes, model),
        edit_project: user.allowed_in_project?(:edit_project, model)
      }

      case permissions
      in { edit_project_attributes: true, edit_project: false }
        super + without_custom_fields(changed_by_user)
      in { edit_project_attributes: false, edit_project: true }
        super + with_custom_fields_only(changed_by_user)
      else
        super
      end
    end

    def without_custom_fields(changes)
      changes.grep_v(/^custom_field_/)
    end

    def with_custom_fields_only(changes)
      changes.grep(/^custom_field_/)
    end

    def manage_permission
      if changed_by_user == ["active"]
        :archive_project
      elsif options[:project_attributes_only]
        :edit_project_attributes
      else
        # if "active" is changed, :archive_project permission will also be
        # checked in `Projects::BaseContract#validate_changing_active`
        :edit_project
      end
    end
  end
end
