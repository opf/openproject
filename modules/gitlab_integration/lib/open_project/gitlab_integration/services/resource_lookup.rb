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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module GitlabIntegration
    module Services
      module ResourceLookup
        private

        # We used to have a bug where the external ID (unique) would be filled with the user-visible number (not unique)
        # making it unsuitable for identification. We filter these out by ensuring external_id and display_id to be different.
        # When they are the same (either because data is bad OR because "bad luck") we match by URL as a fallback.
        # Long-term goal: No fallback, expect external IDs to be correct (active resources will "heal" through upserts)
        def find_resource(scope, external_id:, web_url:)
          scope.where("display_id != external_id").find_by(external_id: external_id.to_s) ||
            scope.find_by(web_url:)
        end

        def find_or_initialize_resource(scope, external_id:, web_url:)
          find_resource(scope, external_id:, web_url:) || scope.new
        end
      end
    end
  end
end
