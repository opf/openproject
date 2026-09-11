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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module GitlabIntegration
    module Services
      class UpsertBranch
        include ParamsHelper

        def call(payload, name:, work_package:)
          GitlabBranch
            .find_or_initialize_by(gitlab_project_id: payload.project_id, name:)
            .tap { |branch| branch.update!(work_package:, **extract_params(payload, name)) }
        end

        private

        def extract_params(payload, name)
          {
            gitlab_html_url: "#{payload.repository.homepage}/-/tree/#{name}",
            repository: payload.repository.name,
            username: payload.user_username?,
            gitlab_user_avatar_url: avatar_url(payload.user_avatar?)
          }
        end
      end
    end
  end
end
