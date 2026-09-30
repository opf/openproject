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
    # Handles Gitlab merge request notifications.
    class MergeRequestHook
      include OpenProject::GitlabIntegration::NotificationHandler::Helper

      ACCEPTED_ACTIONS = %w[open update reopen].freeze
      ACCEPTED_ACTIONS_FOR_COMMENTS = %w[open reopen].freeze
      ACCEPTED_STATES = %w[closed merged].freeze

      def process(payload_params) # rubocop:disable Metrics/AbcSize
        @payload = wrap_payload(payload_params)
        return unless ACCEPTED_ACTIONS.include?(mr_attributes.action) || ACCEPTED_STATES.include?(mr_attributes.state)

        user = User.find_by(id: payload.open_project_user_id)
        text = [mr_attributes.title, mr_attributes.description].compact_blank.join(" - ")
        work_packages = find_mentioned_work_packages(text, user)
        notes = generate_notes(payload)

        if ACCEPTED_ACTIONS_FOR_COMMENTS.include?(mr_attributes.action) || ACCEPTED_STATES.include?(mr_attributes.state)
          comment_on_referenced_work_packages(work_packages, user, notes)
        end
        upsert_merge_request(work_packages)
      end

      private

      attr_reader :payload

      def mr_attributes = payload.object_attributes

      def generate_notes(payload) # rubocop:disable Metrics/AbcSize
        key = {
          "opened" => "opened",
          "reopened" => "reopened",
          "closed" => "closed",
          "merged" => "merged",
          "edited" => "referenced",
          "referenced" => "referenced"
        }[mr_attributes.state]

        key_action = {
          "reopen" => "reopened"
        }[mr_attributes.action]

        return nil unless key

        I18n.t("gitlab_integration.merge_request_#{key_action || key}_comment",
               mr_number: mr_attributes.iid,
               mr_title: mr_attributes.title,
               mr_url: mr_attributes.url,
               repository: payload.repository.name,
               repository_url: payload.repository.url,
               gitlab_user: payload.user.name,
               gitlab_user_url: payload.user.avatar_url)
      end

      def merge_request
        return @merge_request if defined?(@merge_request)

        @merge_request = GitlabMergeRequest.find_by(gitlab_html_url: mr_attributes.url)
      end

      def upsert_merge_request(work_packages)
        return if work_packages.empty? && merge_request.nil?

        OpenProject::GitlabIntegration::Services::UpsertMergeRequest.new.call(payload, work_packages:)
      end
    end
  end
end
