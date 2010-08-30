class RbWikisController < RbApplicationController
  unloadable
  
  def show
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:sprint_id]})
    redirect_to :controller => 'wiki', :action => 'index', :id => @project.id, :page => sprint.wiki_page
  end

  def edit
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:sprint_id]})
    redirect_to :controller => 'wiki', :action => 'edit', :id => @project.id, :page => sprint.wiki_page
  end
end