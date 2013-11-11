class RbWikisController < RbApplicationController
  unloadable
  
  # NOTE: The methods #show and #edit are public (see init.rb). We will let
  # OpenProject's WikiController#index take care of autorization
  #
  # NOTE: The methods #show and #edit create a template page when called.
  def show
    redirect_to :controller => '/wiki', :action => 'index', :project_id => @project.id, :id => @sprint.wiki_page
  end

  def edit
    redirect_to :controller => '/wiki', :action => 'edit', :project_id => @project.id, :id => @sprint.wiki_page
  end
end
