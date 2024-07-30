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
    # Handles Gitlab comment notifications.
    class NoteHook
      include OpenProject::GitlabIntegration::NotificationHandler::Helper

      # TODO: this can be more refactored and simplified...
      def process(payload_params)
        @payload = wrap_payload(payload_params)
        user = User.find_by(id: payload.open_project_user_id)
        text = payload.object_attributes.note
        work_packages = find_mentioned_work_packages(text, user, payload.object_kind)
        if work_packages.empty? && payload.object_attributes.noteable_type == "Issue"
          text = "#{payload.issue.title} - #{payload.object_attributes.note}"
          work_packages = find_mentioned_work_packages(text, user, payload.object_kind)
          work_packages_excluded = find_excluded_work_packages(text, user)
          work_packages = work_packages - work_packages_excluded unless work_packages_excluded.empty?
          return if work_packages.empty?

          notes = generate_notes(payload, "comment")
        elsif work_packages.empty? && payload.object_attributes.noteable_type == "Snippet"
          text = "#{payload.snippet.title} - #{payload.object_attributes.note}"
          work_packages = find_mentioned_work_packages(text, user, payload.object_kind)
          work_packages_excluded = find_excluded_work_packages(text, user)
          work_packages = work_packages - work_packages_excluded unless work_packages_excluded.empty?
          return if work_packages.empty?

          notes = generate_notes(payload, "reference")
        elsif work_packages.empty? && payload.object_attributes.noteable_type == "MergeRequest"
          text = "#{payload.merge_request.title} - #{payload.object_attributes.note}"
          work_packages = find_mentioned_work_packages(text, user, payload.object_kind)
          work_packages_excluded = find_excluded_work_packages(text, user)
          work_packages = work_packages - work_packages_excluded unless work_packages_excluded.empty?
          return if work_packages.empty?

          notes = generate_notes(payload, "comment")
        else
          notes = generate_notes(payload, "reference")
        end
        comment_on_referenced_work_packages(work_packages, user, notes)
        if payload.object_attributes.noteable_type == "Issue"
          upsert_issue(work_packages)
        end
      end

      private

      attr_reader :payload

      # TODO: add key list to simplify the code...
      def generate_notes(payload, note_type)
        case payload.object_attributes.noteable_type
        when "Commit"
          commit_id = payload.commit.id
          I18n.t("gitlab_integration.note_commit_referenced_comment",
                 commit_id: commit_id[0, 8],
                 commit_url: payload.object_attributes.url,
                 commit_note: payload.object_attributes.note,
                 repository: payload.repository.name,
                 repository_url: payload.repository.homepage,
                 gitlab_user: payload.user.name,
                 gitlab_user_url: payload.user.avatar_url)
        when "MergeRequest"
          if note_type == "comment"
            I18n.t("gitlab_integration.note_mr_commented_comment",
                   mr_number: payload.merge_request.iid,
                   mr_title: payload.merge_request.title,
                   mr_url: payload.object_attributes.url,
                   mr_note: payload.object_attributes.note,
                   repository: payload.repository.name,
                   repository_url: payload.repository.homepage,
                   gitlab_user: payload.user.name,
                   gitlab_user_url: payload.user.avatar_url)
          elsif note_type == "reference"
            I18n.t("gitlab_integration.note_mr_referenced_comment",
                   mr_number: payload.merge_request.iid,
                   mr_title: payload.merge_request.title,
                   mr_url: payload.object_attributes.url,
                   mr_note: payload.object_attributes.note,
                   repository: payload.repository.name,
                   repository_url: payload.repository.homepage,
                   gitlab_user: payload.user.name,
                   gitlab_user_url: payload.user.avatar_url)
          end
        when "Issue"
          if note_type == "comment"
            I18n.t("gitlab_integration.note_issue_commented_comment",
                   issue_number: payload.issue.iid,
                   issue_title: payload.issue.title,
                   issue_url: payload.object_attributes.url,
                   issue_note: payload.object_attributes.note,
                   repository: payload.repository.name,
                   repository_url: payload.repository.homepage,
                   gitlab_user: payload.user.name,
                   gitlab_user_url: payload.user.avatar_url)
          elsif note_type == "reference"
            I18n.t("gitlab_integration.note_issue_referenced_comment",
                   issue_number: payload.issue.iid,
                   issue_title: payload.issue.title,
                   issue_url: payload.object_attributes.url,
                   issue_note: payload.object_attributes.note,
                   repository: payload.repository.name,
                   repository_url: payload.repository.homepage,
                   gitlab_user: payload.user.name,
                   gitlab_user_url: payload.user.avatar_url)
          end
        when "Snippet"
          I18n.t("gitlab_integration.note_snippet_referenced_comment",
                 snippet_number: payload.snippet.id,
                 snippet_title: payload.snippet.title,
                 snippet_url: payload.object_attributes.url,
                 snippet_note: payload.object_attributes.note,
                 repository: payload.repository.name,
                 repository_url: payload.repository.homepage,
                 gitlab_user: payload.user.name,
                 gitlab_user_url: payload.user.avatar_url)
        end
      end

      def gitlab_issue
        @gitlab_issue ||= GitlabIssue
                            .where(gitlab_id: payload.issue.iid)
                            .or(GitlabIssue.where(gitlab_html_url: payload.issue.url))
                            .take
      end

      def upsert_issue(work_packages)
        return if work_packages.empty? && gitlab_issue.nil?

        OpenProject::GitlabIntegration::Services::UpsertIssueNote.new.call(payload,
                                                                           work_packages:)
      end
    end
  end
end
