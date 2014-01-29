
OpenProject::Application.routes.draw do

  scope "", as: "pdf_export" do
    resources :export_card_configurations, :controller => :export_card_configurations do
      post 'activate', on: :member
      post 'deactivate', on: :member
    end
  end

end