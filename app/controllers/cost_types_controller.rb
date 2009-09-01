class CostTypesController < ApplicationController
  unloadable
  
  before_filter :authorize

  verify :method => :post, :only => :destroy, :redirect_to => { :action => :details }
  
  def index
  end
  
  
end