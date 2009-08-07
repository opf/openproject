class CostsController < ApplicationController
  unloadable
  
  before_filter :find_deliverable, :only => [:show, :edit]
  before_filter :find_deliverables, :only => [:bulk_edit, :detroy]
  
  before_filter :find_project, :only => [:new, :update_form, :preview]
  before_filter :authorize

  verify :method => :post, :only => :destroy, :redirect_to => { :action => :details }
end