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

class AuthSourcesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :template => :index }

  def index
    @auth_source_pages, @auth_sources = paginate auth_source_class.name.tableize, :per_page => 10
    render "auth_sources/index"
  end

  def new
    @auth_source = auth_source_class.new
    render 'auth_sources/new'
  end

  def create
    @auth_source = auth_source_class.new(params[:auth_source])
    if @auth_source.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render 'auth_sources/new'
    end
  end

  def edit
    @auth_source = AuthSource.find(params[:id])
    render 'auth_sources/edit'
  end

  def update
    @auth_source = AuthSource.find(params[:id])
    if @auth_source.update_attributes(params[:auth_source])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render 'auth_sources/edit'
    end
  end

  def test_connection
    @auth_method = AuthSource.find(params[:id])
    begin
      @auth_method.test_connection
      flash[:notice] = l(:notice_successful_connection)
    rescue => text
      flash[:error] = l(:error_unable_to_connect, text.message)
    end
    redirect_to :action => 'index'
  end

  def destroy
    @auth_source = AuthSource.find(params[:id])
    unless @auth_source.users.find(:first)
      @auth_source.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to :action => 'index'
  end

  protected

  def auth_source_class
    AuthSource
  end
end
