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
    #   sender: <the github user who opened a pull request> (might not appear on closed, synchronized, or reopened - we habven't checked)
    #   repo: <the repository in action>
    # }
    def self.pull_request(payload)
      puts "pull_request", payload
    end

    ##
    # Parses the given source string and returns a list of work_package ids
    # which it finds.
    # WorkPackages are identified by their URL.
    # Params:
    #  source: string
    # Returns:
    #   Array<int>
    private def self.parse_work_package(source)
      []
    end

  end
end
