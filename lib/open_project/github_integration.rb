require 'octokit'

module OpenProject
  module GithubIntegration
    require "open_project/github_integration/engine"

    REQUIRED_PERMISSIONS = %w{}

    def self.github_api
      require 'pry'; binding.pry
      Octokit::Client.new :access_token => Setting.plugin_openproject_github_integration["github_access_token"]
    end
  end
end
