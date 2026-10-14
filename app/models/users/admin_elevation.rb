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

module Users
  module AdminElevation
    PERMISSIONS_WITHOUT_ELEVATION = %i[view_project].freeze

    def self.default
      if OpenProject::FeatureDecisions.admin_privilege_elevation_active?
        none
      else
        everywhere
      end
    end

    def self.default_for(user)
      RequestStore.store.fetch(:admin_elevations, {}).fetch(user.id) { default }
    end

    def self.from_h(hash)
      case hash["type"]
      when "everywhere" then everywhere
      when "in_projects" then in_projects(hash["project_ids"])
      else none
      end
    end

    def self.everywhere
      Everywhere.new
    end

    def self.in_projects(project_ids)
      InProjects.new(project_ids)
    end

    def self.none
      None.new
    end

    def self.for_session(user, session_id)
      return everywhere unless OpenProject::FeatureDecisions.admin_privilege_elevation_active?

      project_ids = user
                      .admin_elevation_sessions
                      .active
                      .for_session(session_id)
                      .includes(:project)
                      .flat_map(&:project_ids)

      project_ids.empty? ? none : in_projects(project_ids.uniq)
    end

    def self.for_api_token(token)
      return everywhere unless OpenProject::FeatureDecisions.admin_privilege_elevation_active?

      token.includes_scope?(:admin_elevation) ? everywhere : none
    end
  end
end
