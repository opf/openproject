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

module OpenProject::GitlabIntegration
  module NotificationHandler
    ##
    # Handles Gitlab issue notifications.
    class IssueHook
      include OpenProject::GitlabIntegration::NotificationHandler::Helper

      KEY_ACTIONS = {
        "open" => "opened",
        "reopen" => "reopened",
        "close" => "closed"
      }.freeze
      ALLOWED_ACTIONS = KEY_ACTIONS.keys

      def process(payload_params) # rubocop:disable Metrics/AbcSize
        @payload = wrap_payload(payload_params)
        user = User.find_by(id: payload.open_project_user_id)
        text = [payload.object_attributes.title, payload.object_attributes.description]
          .compact_blank
          .join(" - ")
        work_packages = find_mentioned_work_packages(text, user)
        notes = generate_notes(payload)
        comment_on_referenced_work_packages(work_packages, user, notes)
        upsert_issue(work_packages)
      end

      private

      attr_reader :payload

      def generate_notes(_payload)
        return nil unless allowed_action?

        note_body
      end

      def gitlab_issue
        return @gitlab_issue if defined?(@gitlab_issue)

        @gitlab_issue = GitlabIssue.find_by(gitlab_html_url: payload.object_attributes.url)
      end

      def upsert_issue(work_packages)
        return if work_packages.empty? && gitlab_issue.nil?

        OpenProject::GitlabIntegration::Services::UpsertIssue.new.call(payload,
                                                                       work_packages:)
      end

      def allowed_action?
        ALLOWED_ACTIONS.include?(payload.object_attributes.action)
      end

      def note_slug
        "gitlab_integration.issue_#{KEY_ACTIONS[payload.object_attributes.action]}_referenced_comment"
      end

      def note_body # rubocop:disable Metrics/AbcSize
        I18n.t(note_slug,
               issue_number: payload.object_attributes.iid,
               issue_title: payload.object_attributes.title,
               issue_url: payload.object_attributes.url,
               repository: payload.repository.name,
               repository_url: payload.repository.homepage,
               gitlab_user: payload.user.name,
               gitlab_user_url: payload.user.avatar_url)
      end
    end
  end
end
