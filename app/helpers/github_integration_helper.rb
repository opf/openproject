module GithubIntegrationHelper
  def check_granted_permissions
    OpenProject::GithubIntegration.github_api
  end
end
