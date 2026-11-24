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
  class UpsertMergeRequestService
    include ParamsHelper
    include ResourceLookup

    # Resources are only tracked once they are linked to a work package.
    def call(payload, provider:, work_packages: [])
      mr = find_or_initialize(payload, provider)
      return if mr.new_record? && work_packages.empty?

      mr.update!(work_packages: mr.work_packages | work_packages, **extract_params(payload, provider))
      mr
    end

    private

    def find_or_initialize(payload, provider)
      find_or_initialize_resource(provider.merge_requests,
                                  external_id: payload.object_attributes.id,
                                  web_url: payload.object_attributes.url)
    end

    # Receives the input from the gitlab webhook and translates them
    # to our internal representation.
    # rubocop:disable-next Metrics/AbcSize
    def extract_params(payload, provider)
      {
        external_id: payload.object_attributes.id.to_s,
        repository_user: repository_user(payload.user, provider),
        display_id: payload.object_attributes.iid.to_s,
        web_url: payload.object_attributes.url,
        external_updated_at: payload.object_attributes.updated_at,
        state: state(payload.object_attributes),
        title: payload.object_attributes.title.to_s,
        description: payload.object_attributes.description.to_s,
        project_name: payload.repository.name,
        labels: labels(payload.labels)
      }
    end

    def state(attributes)
      draft = attributes.draft? || attributes.work_in_progress?
      attributes.state == "opened" && draft ? "draft" : attributes.state
    end
  end
end
