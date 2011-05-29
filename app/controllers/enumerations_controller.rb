class EnumerationsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  include CustomFieldsHelper
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
  end

  def new
    begin
      @enumeration = params[:type].constantize.new
    rescue NameError
      @enumeration = Enumeration.new      
    end
  end

  def create
    @enumeration = Enumeration.new(params[:enumeration])
    @enumeration.type = params[:enumeration][:type]
    if @enumeration.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'new'
    end
  end

  def edit
    @enumeration = Enumeration.find(params[:id])
  end

  def update
    @enumeration = Enumeration.find(params[:id])
    @enumeration.type = params[:enumeration][:type] if params[:enumeration][:type]
    if @enumeration.update_attributes(params[:enumeration])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @enumeration = Enumeration.find(params[:id])
    if !@enumeration.in_use?
      # No associated objects
      @enumeration.destroy
      redirect_to :action => 'index'
      return
    elsif params[:reassign_to_id]
      if reassign_to = @enumeration.class.find_by_id(params[:reassign_to_id])
        @enumeration.destroy(reassign_to)
        redirect_to :action => 'index'
        return
      end
    end
    @enumerations = @enumeration.class.find(:all) - [@enumeration]
  #rescue
  #  flash[:error] = 'Unable to delete enumeration'
  #  redirect_to :action => 'index'
  end
end
