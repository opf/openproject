
OpenProject::Application.routes.draw do

  scope "", as: "pdf_export" do
    resources :export_card_configurations, :controller => :export_card_configurations
  end

end