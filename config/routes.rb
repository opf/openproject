OpenProject::Application.routes.draw do
  scope "", as: "webhooks" do
    post "webhooks/:hook_name" => 'webhooks#handle_hook'
    get "webhooks/:hook_name" => 'webhooks#handle_hook'
  end
end
