
OpenProject::Application.routes.draw do

  scope "", as: "pdf_export" do
    resources :taskboard_card_configurations, :controller => :taskboard_card_configurations
  end

end