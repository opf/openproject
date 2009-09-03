class TasksController < ApplicationController
  unloadable
  before_filter :find_item, :only => [:index, :create ]
  before_filter :find_project, :authorize
  
  def index
    render :partial => "items/item", :collection => @item.children
  end
  
  private
  
  def find_project
    @project = if params[:project_id].nil?
                 @item.issue.project
               else
                 Project.find(params[:project_id])
               end
  end
  
  def find_item
    @item = Item.find(params[:item_id])
  end  
end
