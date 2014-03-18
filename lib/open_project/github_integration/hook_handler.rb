module OpenProject::GithubIntegration
  class HookHandler
    KNOWN_EVENTS = %w{ ping pull_request }

    def process(hook, environment, params, user, project)
      event_type = environment['HTTP_X_GITHUB_EVENT']
      event_delivery = environment['HTTP_X_GITHUB_DELIVERY']
      event_type ||= 'ping' if Rails.env == 'development' # pretend to be a ping event, so I can test things a little better. this line should be removed
      user ||= User.first if Rails.env == 'development' # pretend to have a user, so I can test things a little better. this line should be removed
      require 'pry'; binding.pry
      return 404 unless KNOWN_EVENTS.include?(event_type) && event_delivery
      return 403 unless user.present?

      payload = Hash.new
      payload.merge JSON.parse params.require('payload')
      payload.merge project_identifier: project ? project.identifier : nil,
                    user_id: user.id,
                    github_event: event_type,
                    github_delivery: event_delivery

      hook.send_event(event_name(event_type), payload)
      return 200
    end

    private def event_name(github_event_name)
      "github.#{github_event_name}"
    end
  end
end
