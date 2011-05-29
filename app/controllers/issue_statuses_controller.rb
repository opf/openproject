class IssueStatusesController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  verify :method => :post, :only => [ :destroy, :create, :update, :move, :update_issue_done_ratio ],
         :redirect_to => { :action => :index }
         
  def index
    @issue_status_pages, @issue_statuses = paginate :issue_statuses, :per_page => 25, :order => "position"
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @issue_status = IssueStatus.new
  end

  def create
    @issue_status = IssueStatus.new(params[:issue_status])
    if @issue_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @issue_status = IssueStatus.find(params[:id])
  end

  def update
    @issue_status = IssueStatus.find(params[:id])
    if @issue_status.update_attributes(params[:issue_status])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    IssueStatus.find(params[:id]).destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] = l(:error_unable_delete_issue_status)
    redirect_to :action => 'index'
  end  	
  
  def update_issue_done_ratio
    if IssueStatus.update_issue_done_ratios
      flash[:notice] = l(:notice_issue_done_ratios_updated)
    else
      flash[:error] =  l(:error_issue_done_ratios_not_updated)
    end
    redirect_to :action => 'index'
  end
end
