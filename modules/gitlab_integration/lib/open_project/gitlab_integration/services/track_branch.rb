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
      ##
      # GitLab has no branch event: branch creation and deletion arrive as push
      # hooks whose before/after SHA is all zeros. Matched by pattern rather than
      # against a fixed width so SHA-256 repositories, whose object names are 64
      # characters, are detected too.
      class TrackBranch
        include OpenProject::GitlabIntegration::NotificationHandler::Helper

        BLANK_SHA = /\A0+\z/
        HEADS_PREFIX = "refs/heads/"

        def call(payload, user:)
          name = branch_name(payload.ref)
          return if name.blank?

          if payload.before.match?(BLANK_SHA)
            branch_created!(payload, name, user)
          elsif payload.after.match?(BLANK_SHA)
            branch_deleted!(payload.project_id, name)
          end
        end

        private

        def branch_name(ref)
          return unless ref.start_with?(HEADS_PREFIX)

          ref.delete_prefix(HEADS_PREFIX)
        end

        def branch_created!(payload, name, user)
          work_package = find_visible_work_packages(extract_work_package_ids_from_branch(name), user).first
          return if work_package.nil?

          UpsertBranch.new.call(payload, name:, work_package:)
        end

        def extract_work_package_ids_from_branch(branch_name)
          wp_id = WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT.source
          semantic_id = WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source

          # Preferred shape: a path segment that *begins* with a display id, numeric or
          # semantic, optionally followed by "-", "_" or "." and any text — what the
          # "Git snippets" menu produces (see GitActionsService#branchName):
          #   "42" / "42-fix-the-thing"                    -> "42"
          #   "dp-5" / "dp-5-contact-sponsoring-partners"  -> "dp-5"
          #   "task" / "update-readme"                     -> no match
          prefixed = /\A(#{wp_id})(?:[-_.].*)?\z/i

          # Fallback for hand-written branches that bury the id. Matches a whole token
          # shaped like <project slug>-<number> anywhere in the name; a standalone
          # number is never picked up. Unknown slugs simply find no work package.
          #   "update-on-dp-4-send-invitations"  -> "dp-4"
          #   "release-2026-notes"               -> "release-2026"
          #   "dp-4x" / "42-fix-the-thing"       -> no match
          embedded = /(?<![A-Za-z0-9_])(#{semantic_id})(?![A-Za-z0-9_])/i

          ids = branch_name.split("/").filter_map { prefixed.match(it)&.captures&.first }
          ids = branch_name.scan(embedded).flatten if ids.empty?

          ids.first(1).map { it.match?(/\A\d+\z/) ? it : it.upcase }
        end

        def branch_deleted!(gitlab_project_id, name)
          GitlabBranch.find_by(gitlab_project_id:, name:)&.destroy!
        end
      end
    end
  end
end
