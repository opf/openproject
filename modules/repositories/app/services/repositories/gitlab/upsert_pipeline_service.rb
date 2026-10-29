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
module Repositories::Gitlab
  class UpsertPipelineService
    include ParamsHelper
    include ResourceLookup

    def call(payload, provider:)
      merge_request = find_merge_request(payload, provider)
      return if merge_request.nil?

      find_or_initialize(payload, provider, merge_request).tap do |pipeline|
        pipeline.update!(merge_request:, **extract_params(payload, provider))
      end
    end

    private

    # The payload's merge request URL is authoritative: for fork pipelines the
    # pipeline's project is not the merge request's project, so a URL rebuilt
    # from the project would not match. Rebuilding is the fallback for payloads
    # that carry no URL.
    def find_merge_request(payload, provider)
      web_url = payload.merge_request.url?.presence ||
        "#{payload.project.web_url}/-/merge_requests/#{payload.merge_request.iid}"
      find_resource(provider.merge_requests, external_id: payload.merge_request.id, web_url:)
    end

    def find_or_initialize(payload, provider, merge_request)
      provider.pipelines.find_by(external_id: payload.object_attributes.id) ||
        merge_request.pipelines.find_by(web_url: legacy_web_url(payload)) ||
        provider.pipelines.new
    end

    # Receives the input from the gitlab webhook and translates them
    # to our internal representation.
    # rubocop:disable-next Metrics/AbcSize
    def extract_params(payload, provider)
      {
        external_id: payload.object_attributes.id,
        external_project_id: payload.project.id.to_s,
        repository_user: repository_user(payload.user, provider),
        status: payload.object_attributes.status,
        web_url: web_url(payload),
        details_url: "#{payload.project.web_url}/-/commit/#{payload.object_attributes.sha[0..7]}",
        ci_details: payload.builds,
        started_at: payload.object_attributes.created_at,
        completed_at: payload.object_attributes.finished_at
      }
    end

    # Older GitLab versions (~2023) do not send the pipeline URL.
    def web_url(payload)
      payload.object_attributes.url?.presence ||
        "#{payload.project.web_url}/-/pipelines/#{payload.object_attributes.id}"
    end

    # Pipelines used to be stored by their project-scoped iid, which is also
    # what their URL was built from. Matching that URL lets pipelines that were
    # still running during the upgrade be updated instead of duplicated.
    def legacy_web_url(payload)
      "#{payload.project.web_url}/-/pipelines/#{payload.object_attributes.iid}"
    end
  end
end
