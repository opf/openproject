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

class Timelines::TimelinesProjectsController < ApplicationController
  extend Timelines::Pagination::Controller

  unloadable
  helper :timelines

  before_filter :determine_base

  accept_key_auth :index, :show

  timelines_paginate_model Project

  def index
    options = {:order => 'lft'}

    if params[:ids]
      ids, identifiers = params[:ids].split(/,/).map(&:strip).partition { |s| s =~ /^\d*$/ }
      ids = ids.map(&:to_i).sort
      identifiers = identifiers.sort

      options[:conditions] = ["id IN (?) OR identifier IN (?)", ids, identifiers]
    end

    @projects = @base.visible.all(options)
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end

  def show
    @project = @base.find(params[:id])
    authorize
    return if performed?

    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end

  protected

  def determine_base
    if params[:project_type_id]
      @base = Timelines::ProjectType.find(params[:project_type_id]).projects
    else
      @base = Project
    end
  end
end
