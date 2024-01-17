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

class Projects::Settings::CustomFieldsController < Projects::SettingsController
  menu_item :settings_custom_fields

  def show
    @wp_custom_fields = WorkPackageCustomField.order('lower(name)')
  end

  def update
    Project.transaction do
      if update_custom_fields
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = t(:notice_project_cannot_update_custom_fields,
                          errors: @project.errors.full_messages.join(', '))
        raise ActiveRecord::Rollback
      end
    end

    redirect_to project_settings_custom_fields_path(@project)
  end

  private

  def update_custom_fields
    @project.work_package_custom_field_ids = permitted_params.project[:work_package_custom_field_ids]
    @project.save
  end
end
