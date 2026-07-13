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

module Import
  class JiraFetchAndImportProjectsJob < ApplicationJob
    include Import::JiraOpenProjectReferenceCreation

    def perform(jira_import_id)
      jira_import = Import::JiraImport.find(jira_import_id)

      Import::JiraFetchProjectsJob.perform_now(jira_import_id)
      fetch_and_save_users_data(jira_import)

      Journal::NotificationConfiguration.with(false) do
        Journal::EventConfiguration.with(false) do
          jira_import.import_users
          Import::JiraImportProjectsJob.perform_now(jira_import_id)
        end
      end

      jira_import.transition_to!(:imported)
    rescue StandardError => e
      jira_import&.transition_to!(:import_error, error: e.message, error_backtrace: e.backtrace)
      jira_import&.update!(job_id: nil, error: e.message)
    end

    private

    def fetch_and_save_users_data(jira_import)
      user_keys, mention_usernames = collect_user_to_import(jira_import)
      resolve_mention_user_keys(mention_usernames, user_keys, jira_import.client)
      upsert_data = build_users_upsert_data(user_keys, jira_import)
      Import::JiraUser.upsert_all(upsert_data, unique_by: %i[jira_id jira_user_key])
    end

    def collect_user_to_import(jira_import)
      user_keys = Set.new
      mention_usernames = Set.new
      JiraIssue.where(jira_import:).find_each do |issue|
        collect_user_keys_from_issue(user_keys, mention_usernames, issue)
      end
      [user_keys, mention_usernames]
    end

    def collect_user_keys_from_issue(user_keys, mention_usernames, issue)
      payload = issue.payload["fields"]
      collect_field_user_keys(user_keys, mention_usernames, payload)
      collect_comment_user_keys(user_keys, mention_usernames, payload)
      collect_changelog_user_keys(user_keys, issue)
    end

    def collect_field_user_keys(user_keys, mention_usernames, payload)
      payload
        .slice("creator", "reporter", "assignee")
        .each_value { |v| user_keys << v["key"] if v.present? }
      collect_markup_mentions(payload["description"], mention_usernames)
    end

    def collect_comment_user_keys(user_keys, mention_usernames, payload)
      payload.dig("comment", "comments").each do |c|
        user_keys << c.dig("author", "key")
        collect_markup_mentions(c["body"], mention_usernames)
      end
    end

    def resolve_mention_user_keys(mention_usernames, user_keys, jira_client)
      mention_usernames.compact.each do |username|
        user = jira_client.user_by_username(username:)
        user_keys << user["key"] if user.present?
      rescue Import::JiraClient::ApiError => e
        message = "Could not resolve mentioned user '#{username}': #{e.message}"
        if e.status == 404
          Rails.logger.info("#{message} - skipping")
        else
          raise message
        end
      end
    end

    def collect_changelog_user_keys(user_keys, issue)
      (issue.payload.dig("changelog", "histories") || []).each do |entry|
        user_keys << entry.dig("author", "key") if entry.dig("author", "key").present?
      end
    end

    def collect_markup_mentions(text, mention_usernames)
      ast = JiraWikiMarkup::Parser.new(text).parse
      collect_mentions_from_node(ast, mention_usernames)
    end

    # rubocop:disable Metrics/AbcSize
    def collect_mentions_from_node(node, mention_usernames)
      case node
      when JiraWikiMarkup::Nodes::Mention
        mention_usernames << node.username
      when JiraWikiMarkup::Nodes::List
        node.items.each { |item| collect_mentions_from_node(item, mention_usernames) }
      when JiraWikiMarkup::Nodes::ListItem
        node.children.each { |child| collect_mentions_from_node(child, mention_usernames) }
        collect_mentions_from_node(node.sublist, mention_usernames) if node.sublist
      else
        return unless node.respond_to?(:children)

        node.children.each { |child| collect_mentions_from_node(child, mention_usernames) }
      end
    end
    # rubocop:enable Metrics/AbcSize

    def build_users_upsert_data(user_keys, jira_import)
      jira_client = jira_import.client
      updated_at = Time.zone.now
      created_at = updated_at
      user_keys.compact.filter_map do |jira_user_key|
        build_user_upsert_data(
          jira_user_key,
          created_at,
          updated_at,
          jira_import,
          jira_client
        )
      end
    end

    def build_user_upsert_data(jira_user_key, created_at, updated_at, jira_import, jira_client)
      # here we send a direct user request to get group memberships
      # which are not returned by users_search endpoint
      jira_user_by_key = jira_client.user_by_key(key: jira_user_key)
      {
        payload: jira_user_by_key,
        jira_id: jira_import.jira_id,
        jira_import_id: jira_import.id,
        jira_user_key:,
        created_at:,
        updated_at:
      }
    rescue JiraClient::ApiError => e
      if e.status == 404
        # The user for jira_user_key was not found, this may happen for a user in the Jira issue history
        # no longer available in the Jira instance
        Rails.logger.error "Error fetching user data for user key #{jira_user_key}: #{e.message}"
        nil
      else
        raise "Error fetching user data for user key #{jira_user_key}: #{e.message}"
      end
    end
  end
end
