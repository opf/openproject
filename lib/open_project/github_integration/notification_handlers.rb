#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::GithubIntegration

  ##
  # Handles github-related notifications.
  module NotificationHandlers

    ##
    # Handles a pull_request webhook notification.
    # The payload looks similar to this:
    # { open_project_user_id: <the id of the OpenProject user in whose name the webhook is processed>,
    #   github_event: 'pull_request',
    #   github_delivery: <randomly generated ID idenfitying a single github notification>,
    # Have a look at the github documentation about the next keys:
    # http://developer.github.com/v3/activity/events/types/#pullrequestevent
    #   action: 'opened' | 'closed' | 'synchronize' | 'reopened',
    #   number: <pull request number>,
    #   pull_request: <details of the pull request>
    # We observed the following keys to appear. However they are not documented by github
    #   sender: <the github user who opened a pull request> (might not appear on closed,
    #           synchronized, or reopened - we habven't checked)
    #   repository: <the repository in action>
    # }
    def self.pull_request(payload)
      # Don't add comments on new pushes to the pull request => ignore synchronize.
      # Don't add comments about assignments and labels either.
      ignored_actions = %w[synchronize assigned unassigned labeled unlabeled]
      return if ignored_actions.include? payload['action']
      comment_on_referenced_work_packages payload['pull_request']['body'], payload
    rescue => e
      Rails.logger.error "Failed to handle pull_request event: #{e} #{e.message}"
      raise e
    end

    ##
    # Handles an issue_comment webhook notification.
    # The payload looks similar to this:
    # { open_project_user_id: <the id of the OpenProject user in whose name the webhook is processed>,
    #   github_event: 'issue_comment',
    #   github_delivery: <randomly generated ID idenfitying a single github notification>,
    # Have a look at the github documentation about the next keys:
    # http://developer.github.com/v3/activity/events/types/#pullrequestevent
    #   action: 'created',
    #   issue: <details of the pull request/github issue>
    #   comment: <details of the created comment>
    # We observed the following keys to appear. However they are not documented by github
    #   sender: <the github user who opened a pull request> (might not appear on closed,
    #           synchronized, or reopened - we habven't checked)
    #   repository: <the repository in action>
    # }
    def self.issue_comment(payload)
      # if the comment is not associated with a PR, ignore it
      return unless payload['issue']['pull_request']['html_url']
      comment_on_referenced_work_packages payload['comment']['body'], payload
    rescue => e
      Rails.logger.error "Failed to handle issue_comment event: #{e} #{e.message}"
      raise e
    end

    ##
    # Parses the text for links to WorkPackages and adds a comment
    # to those WorkPackages depending on the payload.
    def self.comment_on_referenced_work_packages(text, payload)
      user = User.find_by_id(payload['open_project_user_id'])
      wp_ids = extract_work_package_ids(text)
      wps = find_visible_work_packages(wp_ids, user)

      attributes = { journal_notes: notes_for_payload(payload) }
      wps.each do |wp|
        ::WorkPackages::UpdateService
          .new(user: user, work_package: wp)
          .call(attributes: attributes)
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
      wp_regex = /http(?:s?):\/\/#{Regexp.escape(Setting.host_name)}\/(?:\S+?\/)*(?:work_packages|wp)\/([0-9]+)/

      source.scan(wp_regex).flatten.map {|s| s.to_i }.uniq
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

    ##
    # Find a matching translation for the action specified in the payload.
    def self.notes_for_payload(payload)
      case payload['github_event']
      when 'pull_request'
        notes_for_pull_request_payload(payload)
      when 'issue_comment'
        notes_for_issue_comment_payload(payload)
      else
        raise "GitHub event not supported: #{payload['github_event']}" +
              " (#{payload['github_delivery']})"
      end
    end

    def self.notes_for_pull_request_payload(payload)
      key = {
        'opened' => 'opened',
        'reopened' => 'opened',
        'closed' => 'closed',
        'edited' => 'referenced',
        'referenced' => 'referenced',
        # We ignore synchrize actions for now. See pull_request method.
        'synchronize' => nil
      }[payload['action']]

      # a closed pull request which has been merged
      # deserves a different label :)
      key = 'merged' if key == 'closed' && payload['pull_request']['merged']

      raise "Github action #{payload['action']} " +
            "for event #{payload['github_event']} not supported." unless key

      I18n.t("github_integration.pull_request_#{key}_comment",
             :pr_number => payload['number'],
             :pr_title => payload['pull_request']['title'],
             :pr_url => payload['pull_request']['html_url'],
             :repository => payload['pull_request']['base']['repo']['full_name'],
             :repository_url => payload['pull_request']['base']['repo']['html_url'],
             :github_user => payload['sender']['login'],
             :github_user_url => payload['sender']['html_url'])
    end

    def self.notes_for_issue_comment_payload(payload)
      unless payload['action'] == 'created'
        raise "Github action #{payload['action']} " +
              "for event #{payload['github_event']} not supported."
      end

      I18n.t("github_integration.pull_request_referenced_comment",
             :pr_number => payload['issue']['number'],
             :pr_title => payload['issue']['title'],
             :pr_url => payload['comment']['html_url'],
             :repository => payload['repository']['full_name'],
             :repository_url => payload['repository']['html_url'],
             :github_user => payload['comment']['user']['login'],
             :github_user_url => payload['comment']['user']['html_url'])
    end
  end
end
