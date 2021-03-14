#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    class RootPresenter
      extend HALPresenter
      include ::API::V3::Utilities::PathHelper

      def self.api_v3_paths
        ::API::V3::Utilities::PathHelper::ApiV3Path
      end

      link :self, api_v3_paths.root
      link :configuration, api_v3_paths.configuration
      link :memberships, api_v3_paths.memberships
      link :priorities, api_v3_paths.priorities
      link :relations, api_v3_paths.relations
      link :statuses, api_v3_paths.statuses
      link :time_entries, api_v3_paths.time_entries
      link :types, api_v3_paths.types
      link :user do
        api_v3_paths.user(resource.id)
      end

      link :userPreferences do
        api_v3_paths.my_preferences
      end

      link :workPackages, api_v3_paths.work_packages

      attribute :instance_name do
        Setting.app_title
      end

      attribute :core_version do
        OpenProject::VERSION.to_semver
      end

      attribute :_type, 'Root'
    end
  end
end
