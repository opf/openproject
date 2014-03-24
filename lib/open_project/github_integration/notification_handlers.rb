module OpenProject::GithubIntegration

  ##
  # Handles github-related notifications.
  module NotificationHandlers

    ##
    # Handles a pull_request webhook notification.
    # The payload looks similar to this:
    # { user_id: <the id of the OpenProject user in whose name the webhook is processed>,
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
    #   repo: <the repository in action>
    # }
    def self.pull_request(payload)
      puts '#' * 200
      puts "pull_request", payload.to_json

      # Don't add comments on new pushes to the pull request
      return if payload['action'] == 'synchronize'

      user = User.find_by_id(payload['user_id'])
      wp_ids = extract_work_package_ids(payload['pull_request']['body'])
      wps = find_visible_work_packages(wp_ids, user)

      # FIXME check user is allowed to update work packages
      # TODO mergeable

      wps.each do |wp|
        wp.update_by!(user, :notes => notes_for_payload(payload))
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

      source.scan(wp_regex).flatten.map {|s| s.to_i }
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
        wp.present? && wp.visible?(user)
      end
    end

    def self.notes_for_payload(payload)
      key = {
        'opened' => 'opened',
        'reopened' => 'opened',
        'closed' => 'closed',
        # We ignore synchrize actions for now. See pull_request method.
        'synchronize' => nil
      }[payload['action']]

      I18n.t("github_integration.pull_request_#{key}_comment",
             :pr_number => payload['number'],
             :pr_title => payload['pull_request']['title'],
             :pr_url => payload['pull_request']['url'],
             :repository => payload['pull_request']['base']['repo']['full_name'],
             :repository_url => payload['pull_request']['base']['repo']['html_url'],
             :github_user => payload['pull_request']['user']['login'],
             :github_user_url => payload['pull_request']['user']['html_url'])
    end
  end
end
