#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

class GanttsController < ApplicationController
  menu_item :gantt
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  include QueriesHelper
  include SortHelper
  include Redmine::Export::PDF
  
  def show
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    retrieve_query
    @query.group_by = nil
    @gantt.query = @query if @query.valid?
    
    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
    
    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(@gantt.to_pdf, :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end

  def update
    show
  end

end
