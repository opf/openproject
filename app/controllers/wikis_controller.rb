#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WikisController < ApplicationController
  menu_item :settings
  before_filter :find_project, :authorize

  # Create or update a project's wiki
  def edit
    @wiki = @project.wiki || Wiki.new(:project => @project)
    @wiki.safe_attributes = params[:wiki]
    @wiki.save if request.post?
    # there's is no wiki anymore, see: opf/openproject/master#e375875
    # render(:update) {|page| page.replace_html "tab-content-wiki", :partial => 'projects/settings/wiki'}
    render :nothing => true
  end

  # Delete a project's wiki
  def destroy
    if request.post? && params[:confirm] && @project.wiki
      @project.wiki.destroy
      redirect_to :controller => '/projects', :action => 'settings', :id => @project, :tab => 'wiki'
    end
  end
end
