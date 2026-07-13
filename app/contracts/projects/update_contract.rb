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

module Projects
  class UpdateContract < BaseContract
    def writable_attributes
      # Permission checks must use the original project id, not a user-modified one.
      # Without this, changing the id (e.g. via BCF API) causes permission lookups
      # against the wrong project, corrupting the permission cache and leading to
      # intermittent 403 responses instead of the expected 422.
      with_unchanged_id do
        if allow_project_attributes_only?
          with_available_custom_fields_only(super)
        elsif allow_edit_attributes_only?
          without_custom_fields(super)
        elsif allow_all_attributes?
          # When all attributes are updated (API-only case), allow writing to all available custom
          # fields (including disabled ones) to maintain backward compatibility with the API.
          with_all_available_custom_fields(super)
        else
          []
        end
      end
    end

    private

    def project_attributes_only? = options[:project_attributes_only].present?

    def allow_edit_project? = user.allowed_in_project?(:edit_project, model)

    def allow_edit_project_attributes? = user.allowed_in_project?(:edit_project_attributes, model)

    def allow_edit_attributes_only?
      allow_edit_project? && !project_attributes_only? && !allow_edit_project_attributes?
    end

    def allow_project_attributes_only?
      allow_edit_project_attributes? && (project_attributes_only? || !allow_edit_project?)
    end

    def allow_all_attributes?
      return true if allow_edit_project? && allow_edit_project_attributes? && !project_attributes_only?

      changed_by_user == ["active"] # Allow archiving, permission checked in manage_permission
    end

    def without_custom_fields(changes) = changes.grep_v(/^custom_(field|comment)_/)

    def with_available_custom_fields_only(changes)
      changes & available_custom_fields.flat_map(&:all_attribute_names)
    end

    def with_all_available_custom_fields(changes)
      without_custom_fields(changes) + (changes & all_available_custom_fields.flat_map(&:all_attribute_names))
    end

    def manage_permission
      if changed_by_user == ["active"]
        :archive_project
      elsif project_attributes_only?
        :edit_project_attributes
      else
        # if "active" is changed, :archive_project permission will also be
        # checked in `Projects::BaseContract#validate_changing_active`
        :edit_project
      end
    end
  end
end
