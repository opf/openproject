class RbWikisController < RbApplicationController
  unloadable
  
  # NOTE: This method is public (see init.rb). We will let Redmine core's 
  # WikiController#index tak care of autorization
  def show
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:id]})
    redirect_to :controller => 'wiki', :action => 'index', :id => @project.id, :page => sprint.wiki_page
  end

  # NOTE: This method is public (see init.rb). We will let Redmine core's 
  # WikiController#index tak care of autorization
  def edit
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:id]})
    redirect_to :controller => 'wiki', :action => 'edit', :id => @project.id, :page => sprint.wiki_page
  end
end