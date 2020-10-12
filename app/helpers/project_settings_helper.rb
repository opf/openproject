#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module ProjectSettingsHelper
  extend self
  def project_settings_tabs
    [
      {
        name: 'generic',
        action: { controller: '/project_settings/generic', action: 'show' },
        label: :label_information_plural
      },
      {
        name: 'modules',
        action: { controller: '/project_settings/modules', action: 'show' },
        label: :label_module_plural
      },
      {
        name: 'types',
        action: { controller: '/project_settings/types', action: 'show' },
        label: :label_work_package_types
      },
      {
        name: 'custom_fields',
        action: { controller: '/project_settings/custom_fields', action: 'show' },
        label: :label_custom_field_plural
      },
      {
        name: 'versions',
        action: { controller: '/project_settings/versions', action: 'show' },
        label: :label_version_plural
      },
      {
        name: 'categories',
        action: { controller: '/project_settings/categories', action: 'show' },
        label: :label_work_package_category_plural,
        last: true
      },
      {
        name: 'repository',
        action: { controller: '/project_settings/repository', action: 'show' },
        if: ->(project) { project.enabled_module_names.include? 'repository' },
        label: :label_repository
      },
      {
        name: 'activities',
        action: { controller: '/project_settings/activities', action: 'show' },
        label: :enumeration_activities
      }
    ]
  end
end
