# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
module OpenProject
  module GitlabIntegration
    module Services
      class UpsertMergeRequest
        include ParamsHelper

        def call(payload, work_packages: [])
          find_or_initialize(payload).tap do |mr|
            mr.update!(work_packages: mr.work_packages | work_packages, **extract_params(payload))
          end
        end

        private

        def find_or_initialize(payload)
          GitlabMergeRequest.find_by_gitlab_identifiers(id: payload.object_attributes.iid,
                                                        url: payload.object_attributes.url,
                                                        initialize: true)
        end

        # Receives the input from the gitlab webhook and translates them
        # to our internal representation.
        # rubocop:disable Metrics/AbcSize
        def extract_params(payload)
          {
            gitlab_id: payload.object_attributes.iid,
            gitlab_user: gitlab_user_id(payload.user),
            number: payload.object_attributes.iid,
            gitlab_html_url: payload.object_attributes.url,
            gitlab_updated_at: payload.object_attributes.updated_at,
            state: payload.object_attributes.state,
            title: payload.object_attributes.title,
            body: description(payload.object_attributes.description),
            repository: payload.repository.name,
            draft: payload.object_attributes.work_in_progress,
            merged: payload.object_attributes.state == "merged",
            merged_by: gitlab_user_id(payload.user),
            merged_at: payload.object_attributes.state == "merged" ? payload.object_attributes.updated_at : nil,
            labels: payload.labels.map { |values| extract_label_values(values) }
          }
        end
        # rubocop:enable Metrics/AbcSize

        def extract_label_values(payload)
          {
            title: payload["title"],
            color: payload["color"]
          }
        end

        def gitlab_user_id(payload)
          return if payload.blank?

          ::OpenProject::GitlabIntegration::Services::UpsertGitlabUser.new.call(payload)
        end
      end
    end
  end
end
