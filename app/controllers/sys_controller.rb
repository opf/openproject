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

class SysController < ActionController::Base
  before_filter :check_enabled

  def projects
    p = Project.active.has_module(:repository).find(:all, :include => :repository, :order => 'identifier')
    render :xml => p.to_xml(:include => :repository)
  end

  def create_project_repository
    project = Project.find(params[:id])
    if project.repository
      render :nothing => true, :status => 409
    else
      logger.info "Repository for #{project.name} was reported to be created by #{request.remote_ip}."
      project.repository = Repository.factory(params[:vendor], params[:repository])
      if project.repository && project.repository.save
        render :xml => project.repository, :status => 201
      else
        render :nothing => true, :status => 422
      end
    end
  end

  def fetch_changesets
    projects = []
    if params[:id]
      projects << Project.active.has_module(:repository).find(params[:id])
    else
      projects = Project.active.has_module(:repository).find(:all, :include => :repository)
    end
    projects.each do |project|
      if project.repository
        project.repository.fetch_changesets
      end
    end
    render :nothing => true, :status => 200
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end

  protected

  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :text => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
end
