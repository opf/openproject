class CostReportsController < ApplicationController
  unloadable
  
  before_filter :get_query
  
  def index
    
  end
  
private
  def get_query
    # tries to find a active query in the session or loads the default one
  end
  
end
