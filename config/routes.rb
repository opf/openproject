OpenProject::Application.routes.draw do
  scope "settings/plugin/openproject_github_integration", as: "github_integration_settings" do
    post "link_github_account" => 'settings#link_to_github_redirect'
    post "link_github_account_back" => 'settings#link_to_github_back'
  end
end
