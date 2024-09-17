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

module OpenProject::Backlogs::Patches::Versions::BaseContractPatch
  private

  def user_allowed_to_manage
    changed_settings = model.version_settings.select(&:changed?)

    super unless !model.changed? && changed_settings.any?

    # Make sure the version_settings (column=left|right|none) can only be stored
    # for projects the user has the :manage_versions permission in.
    changed_settings.each do |version_setting|
      unless user.allowed_in_project?(:manage_versions, Project.find_by(id: version_setting.project_id))
        errors.add :base, :error_unauthorized
      end
    end
  end
end
