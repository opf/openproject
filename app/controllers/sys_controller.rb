# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class SysController < ActionController::Base
  wsdl_service_name 'Sys'
  web_service_api SysApi
  web_service_scaffold :invoke
  
  before_invocation :check_enabled
  
  def projects
    Project.find(:all, :include => :repository)
  end

  def repository_created(project_id, url)
    project = Project.find_by_id(project_id)
    return 0 unless project && project.repository.nil?
    logger.debug "Repository for #{project.name} created"
    repository = Repository.new(:project => project, :url => url)
    repository.root_url = url
    repository.save
    repository.id
  end

protected

  def check_enabled(name, args)
    Setting.sys_api_enabled?
  end
end
