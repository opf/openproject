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

module Repositories
  module WorkPackageMentions
    ##
    # Parses the given source string and returns a list of work package display identifiers
    # (numeric strings or semantic IDs like "PROJ-42") found in that text.
    # WorkPackages are identified by their URL or by an OP#/PP# prefix.
    # Params:
    #  source: string
    #  kind: "" (default) | "note" | "private"
    # Returns:
    #   Array<String>
    def extract_work_package_ids(text, kind = "")
      # matches the following things (given that `Setting.host_name` equals 'www.openproject.org')
      #  - http://www.openproject.org/wp/1234
      #  - https://www.openproject.org/wp/1234
      #  - http://www.openproject.org/work_packages/1234
      #  - https://www.openproject.org/subdirectory/work_packages/1234
      # Or with the following prefix: OP# PP#
      # e.g.,: This is a reference to OP#1234 or OP#PROJ-42
      # For private comments you can use the prefix: PP#
      host_name = Regexp.escape(Setting.host_name)
      wp_id     = WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT
      url_part  = /http(?:s?):\/\/#{host_name}\/(?:\S+?\/)*(?:work_packages|wp)\/(#{wp_id})/

      wp_regex = case kind
                 when "private"
                   /PP#(#{wp_id})/
                 when "note"
                   /OP#(#{wp_id})|#{url_part}/
                 else
                   /OP#(#{wp_id})|PP#(#{wp_id})|#{url_part}/
                 end

      String(text)
        .scan(wp_regex)
        .filter_map { |groups| groups.compact.first }
        .uniq
    end

    ##
    # Given a list of work package display identifiers this methods returns all work packages
    # that match those identifiers and are visible by the given user.
    # Params:
    #  - Array<String>: A list of WorkPackage display identifiers
    #  - User: The user who may (or may not) see those WorkPackages
    # Returns:
    #  - Array<WorkPackage>
    def find_visible_work_packages(ids, user)
      WorkPackage
        .includes(:project)
        .where_display_id_in(ids)
        .select { |wp| user.allowed_in_work_package?(:add_work_package_comments, wp) }
    end

    # Returns a list of `WorkPackage`s that were referenced in the `text` and are visible to the given `user`.
    def find_mentioned_work_packages(text, user, kind = "")
      find_visible_work_packages(extract_work_package_ids(text, kind), user)
    end

    # Returns a list of `WorkPackage`s that were excluded in the `text`.
    def find_excluded_work_packages(text, user)
      find_visible_work_packages(extract_work_package_ids(text, "private"), user)
    end

    ##
    # Adds comments to the given WorkPackages.
    def comment_on_referenced_work_packages(work_packages, user, notes)
      return if notes.nil?

      work_packages.each do |work_package|
        ::AddWorkPackageNoteService.new(user:, work_package:).call(notes, send_notifications: false)
      end
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
  end
end
