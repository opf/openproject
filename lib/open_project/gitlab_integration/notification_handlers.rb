#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::GitlabIntegration

  ##
  # Handles gitlab-related notifications.
  module NotificationHandlers

    def self.merge_request_hook(payload)
      accepted_actions = %w[open]
      accepted_states = %w[closed merged]
      return unless (accepted_actions.include? payload['object_attributes']['action']) || (accepted_states.include? payload['object_attributes']['state'])
      comment_on_referenced_work_packages payload['object_attributes']['title'], payload

    rescue => e
      Rails.logger.error "Failed to handle merge_request_hook event: #{e} #{e.message}"
      raise e
    end

    def self.note_hook(payload)
      comment_on_referenced_work_packages payload['object_attributes']['note'], payload

    rescue => e
      Rails.logger.error "Failed to handle note_hook event: #{e} #{e.message}"
      raise e
    end

    def self.push_hook(payload)
      push_hook_split_commits payload
      
    rescue => e
      Rails.logger.error "Failed to handle push_hook event: #{e} #{e.message}"
      raise e
    end

    def self.issue_hook(payload)
      comment_on_referenced_work_packages payload['object_attributes']['title'] + ' - ' + payload['object_attributes']['description'], payload
      
    rescue => e
      Rails.logger.error "Failed to handle issue_hook event: #{e} #{e.message}"
      raise e
    end

    def self.push_hook_split_commits(payload)
      return nil unless payload['object_kind'] == 'push'
      payload[:commits].each do |commit|
        # concatenated to check title and description in one step
        text = commit['title'] + " - " + commit['message']
        comment_on_referenced_work_packages text, payload, commit
      end
    end

    def self.comment_on_referenced_work_packages(text, payload, commit = nil)
      user = User.find_by_id(payload['open_project_user_id'])
      wp_ids = extract_work_package_ids(text)
      wps = find_visible_work_packages(wp_ids, user)
      if payload['object_kind'] == 'push'
        notes = notes_for_push_payload(commit, payload)
      elsif payload['object_kind'] == 'issue'
        notes = notes_for_issue_payload(payload)
      elsif payload['object_kind'] == 'merge_request'
        notes = notes_for_merge_request_payload(payload)
      elsif payload['object_kind'] == 'note'
        if wps.empty? && payload['object_attributes']['noteable_type'] == 'Issue'
          wp_ids = extract_work_package_ids(payload['issue']['title'] + ' - ' + payload['object_attributes']['note'])
          wps = find_visible_work_packages(wp_ids, user)
          notes = notes_for_note_payload(payload, 'comment')
        elsif wps.empty? && payload['object_attributes']['noteable_type'] == 'MergeRequest'
          wp_ids = extract_work_package_ids(payload['merge_request']['title'] + ' - ' + payload['object_attributes']['note'])
          wps = find_visible_work_packages(wp_ids, user)
          notes = notes_for_note_payload(payload, 'comment')
        else
          notes = notes_for_note_payload(payload, 'reference')
        end
      else
        return
      end

      return if notes.nil?

      if payload['object_kind'] == 'merge_request'
        if payload['object_attributes']['state'] == 'opened'
          attributes = { journal_notes: notes, status_id: 7 }
        elsif payload['object_attributes']['state'] == 'merged'
          attributes = { journal_notes: notes, status_id: 8 }
        else
          attributes = { journal_notes: notes }
        end
      else
        attributes = { journal_notes: notes }
      end
      
      wps.each do |wp|
        ::WorkPackages::UpdateService
          .new(user: user, model: wp)
          .call(attributes.merge(send_notifications: false).symbolize_keys)
      end
    end

    ##
    # Parses the given source string and returns a list of work_package ids
    # which it finds.
    # WorkPackages are identified by their URL.
    # Params:
    #  source: string
    # Returns:
    #   Array<int>
    def self.extract_work_package_ids(source)
      # matches the following things (given that `Setting.host_name` equals 'www.openproject.org')
      #  - http://www.openproject.org/wp/1234
      #  - https://www.openproject.org/wp/1234
      #  - http://www.openproject.org/work_packages/1234
      #  - https://www.openproject.org/subdirectory/work_packages/1234
      # Or with the following prefix: OP#
      # e.g.,: This is a reference to OP#1234
      host_name = Regexp.escape(Setting.host_name)
      wp_regex = /OP#(\d+)|http(?:s?):\/\/#{host_name}\/(?:\S+?\/)*(?:work_packages|wp)\/([0-9]+)/

      source.scan(wp_regex)
        .map {|first, second| (first || second).to_i }
        .select { |el| el > 0 }
        .uniq
    end

    ##
    # Given a list of work package ids this methods returns all work packages that match those ids
    # and are visible by the given user.
    # Params:
    #  - Array<int>: An list of WorkPackage ids
    #  - User: The user who may (or may not) see those WorkPackages
    # Returns:
    #  - Array<WorkPackage>
    def self.find_visible_work_packages(ids, user)
      ids.collect do |id|
        WorkPackage.includes(:project).find_by_id(id)
      end.select do |wp|
        wp.present? && user.allowed_to?(:add_work_package_notes, wp.project)
      end
    end

    def self.notes_for_issue_payload(payload)
      return nil unless payload['object_attributes']['action'] == 'open' || payload['object_attributes']['state'] == 'closed'
      I18n.t("gitlab_integration.issue_#{payload['object_attributes']['state']}_referenced_comment",
        :issue_number => payload['object_attributes']['iid'],
        :issue_title => payload['object_attributes']['title'],
        :issue_url => payload['object_attributes']['url'],
        :repository => payload['repository']['name'],
        :repository_url => payload['repository']['homepage'],
        :gitlab_user => payload['user']['name'],
        :gitlab_user_url => payload['user']['avatar_url'])
    end

    def self.notes_for_push_payload(commit, payload)
      commit_id = commit['id']
      I18n.t("gitlab_integration.push_single_commit_comment",
        :commit_number => commit_id[0, 8],
        :commit_note => commit['message'],
        :commit_url => commit['url'],
        :commit_timestamp => commit['timestamp'],
        :repository => payload['repository']['name'],
        :repository_url => payload['repository']['homepage'],
        :gitlab_user => payload['user_name'],
        :gitlab_user_url => payload['user_avatar'])
    end

    def self.notes_for_merge_request_payload(payload)
      key = {
        'opened' => 'opened',
        'reopened' => 'opened',
        'closed' => 'closed',
        'merged' => 'merged',
        'edited' => 'referenced',
        'referenced' => 'referenced'
      }[payload['object_attributes']['state']]

      return nil unless key

      I18n.t("gitlab_integration.merge_request_#{key}_comment",
        :mr_number => payload['object_attributes']['id'],
        :mr_title => payload['object_attributes']['title'],
        :mr_url => payload['object_attributes']['url'],
        :repository => payload['repository']['name'],
        :repository_url => payload['repository']['url'],
        :gitlab_user => payload['user']['name'],
        :gitlab_user_url => payload['user']['avatar_url'])
    end

    def self.notes_for_note_payload(payload, note_type)
      if payload['object_attributes']['noteable_type'] == 'Commit'
        commit_id = payload['commit']['id']
        I18n.t("gitlab_integration.note_commit_referenced_comment",
          :commit_id => commit_id[0, 8],
          :commit_url => payload['object_attributes']['url'],
          :commit_note => payload['object_attributes']['note'],
          :repository => payload['repository']['name'],
          :repository_url => payload['repository']['homepage'],
          :gitlab_user => payload['user']['name'],
          :gitlab_user_url => payload['user']['avatar_url'])
      elsif payload['object_attributes']['noteable_type'] == 'MergeRequest'
        if note_type == 'comment'
          I18n.t("gitlab_integration.note_mr_commented_comment",
            :mr_number => payload['merge_request']['id'],
            :mr_title => payload['merge_request']['title'],
            :mr_url => payload['object_attributes']['url'],
            :mr_note => payload['object_attributes']['note'],
            :repository => payload['repository']['name'],
            :repository_url => payload['repository']['homepage'],
            :gitlab_user => payload['user']['name'],
            :gitlab_user_url => payload['user']['avatar_url'])
        elsif note_type == 'reference'
          I18n.t("gitlab_integration.note_mr_referenced_comment",
            :mr_number => payload['merge_request']['id'],
            :mr_title => payload['merge_request']['title'],
            :mr_url => payload['object_attributes']['url'],
            :mr_note => payload['object_attributes']['note'],
            :repository => payload['repository']['name'],
            :repository_url => payload['repository']['homepage'],
            :gitlab_user => payload['user']['name'],
            :gitlab_user_url => payload['user']['avatar_url'])
        end
      elsif payload['object_attributes']['noteable_type'] == 'Issue'
        if note_type == 'comment'
          I18n.t("gitlab_integration.note_issue_commented_comment",
            :issue_number => payload['issue']['iid'],
            :issue_title => payload['issue']['title'],
            :issue_url => payload['object_attributes']['url'],
            :issue_note => payload['object_attributes']['note'],
            :repository => payload['repository']['name'],
            :repository_url => payload['repository']['homepage'],
            :gitlab_user => payload['user']['name'],
            :gitlab_user_url => payload['user']['avatar_url'])
        elsif note_type == 'reference'
          I18n.t("gitlab_integration.note_issue_referenced_comment",
            :issue_number => payload['issue']['iid'],
            :issue_title => payload['issue']['title'],
            :issue_url => payload['object_attributes']['url'],
            :issue_note => payload['object_attributes']['note'],
            :repository => payload['repository']['name'],
            :repository_url => payload['repository']['homepage'],
            :gitlab_user => payload['user']['name'],
            :gitlab_user_url => payload['user']['avatar_url'])
        end
      elsif payload['object_attributes']['noteable_type'] == 'Snippet'
        I18n.t("gitlab_integration.note_snippet_referenced_comment",
          :snippet_number => payload['snippet']['id'],
          :snippet_title => payload['snippet']['title'],
          :snippet_url => payload['object_attributes']['url'],
          :snippet_note => payload['object_attributes']['note'],
          :repository => payload['repository']['name'],
          :repository_url => payload['repository']['homepage'],
          :gitlab_user => payload['user']['name'],
          :gitlab_user_url => payload['user']['avatar_url'])
      else
        return nil
      end
    end
  end
end
