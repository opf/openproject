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

module OpenProject::Backlogs::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_versions
      super

      version_data = Array(project_data.lookup("versions"))
      return if version_data.blank?

      versions = version_data
        .filter_map { |data| Version.find_by(name: data["name"]) }

      versions.each do |version|
        display = version_settings_display_map[version.name] || VersionSetting::DISPLAY_NONE
        version.version_settings.create! display:, project: version.project
      end
    end

    ##
    # This relies on the names from the core's `config/locales/en.seeders.yml`.
    def version_settings_display_map
      {
        "Sprint 1" => VersionSetting::DISPLAY_LEFT,
        "Sprint 2" => VersionSetting::DISPLAY_LEFT,
        "Bug Backlog" => VersionSetting::DISPLAY_RIGHT,
        "Product Backlog" => VersionSetting::DISPLAY_RIGHT,
        "Wish List" => VersionSetting::DISPLAY_RIGHT
      }
    end
  end
end
