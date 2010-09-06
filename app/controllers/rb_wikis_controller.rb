class RbWikisController < RbApplicationController
  unloadable
  
  # NOTE: This method is public (see init.rb). We will let Redmine core's 
  # WikiController#index tak care of autorization
  # NOTE: this method does create a template page when called.
  def show
    redirect_to :controller => 'wiki', :action => 'index', :id => @project.id, :page => @sprint.wiki_page
  end

  # NOTE: This method is public (see init.rb). We will let Redmine core's 
  # WikiController#index tak care of autorization
  # NOTE: this method does create a template page when called.
  def edit
    redirect_to :controller => 'wiki', :action => 'edit', :id => @project.id, :page => @sprint.wiki_page
  end
end
