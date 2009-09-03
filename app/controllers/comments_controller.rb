class CommentsController < ApplicationController
  unloadable
  before_filter :authorize
  before_filter :find_item, :only => [:index, :create ]
  
  def index
    @journals = @item.issue.journals.find(:all, 
                                          :include => [:user, :details], 
                                          :order => "#{Journal.table_name}.created_on DESC",
                                          :conditions => "notes!=''")
    render :partial => "comment", :collection => @journals, :as => :journal
  end
  
  def create
    journal = @item.issue.init_journal(User.current, params[:comment])
    journal.save!
    journal.reload
    render :partial => "comment", :locals => { :journal => journal }
  end
  
  private
    
  def find_item
    @item = Item.find(params[:item_id])
  end  
end
