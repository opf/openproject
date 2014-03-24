module OpenProject::GithubIntegration
  module NotificationHandlers
    def self.ping(payload)
      puts "ping", payload
    end

    def self.pull_request(payload)
      puts "pull_request", payload
    end

  end
end
