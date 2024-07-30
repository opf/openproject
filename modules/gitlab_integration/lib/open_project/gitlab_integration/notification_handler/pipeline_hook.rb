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

module OpenProject::GitlabIntegration
  module NotificationHandler
    ##
    # Handles Gitlab pipeline notifications.
    class PipelineHook
      include OpenProject::GitlabIntegration::NotificationHandler::Helper

      def process(payload_params)
        @payload = wrap_payload(payload_params)

        return if payload.merge_request.blank?

        merge_request = find_merge_request
        return unless merge_request
        return unless associated_with_mr?

        # disabled until gitlab issue resolution
        OpenProject::GitlabIntegration::Services::UpsertPipeline.new.call(
          payload,
          merge_request:
        )
      end

      private

      attr_reader :payload

      def associated_with_mr?
        payload.merge_request.iid.present?
      end

      def find_merge_request
        gitlab_id = payload.merge_request.iid
        GitlabMergeRequest.find_by(gitlab_id:)
      end
    end
  end
end
