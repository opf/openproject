
OpenProject::Application.routes.draw do

  scope "", as: "pdf_export" do
    scope "projects/:project_id", as: 'project' do
      resources :pdf_export, :controller => :pdf_export, :only => [:index, :show]
      resources :taskboard_card_configurations, :controller => :taskboard_card_configurations, :only => [:edit, :update]
      resources :taskboard_cards, :controller => :taskboard_cards, :only => [:index]
    end
  end

end