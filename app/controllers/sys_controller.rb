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
  
  # Returns the projects list, with their repositories
  def projects_with_repository_enabled
    Project.has_module(:repository).find(:all, :include => :repository, :order => 'identifier')
  end

  # Registers a repository for the given project identifier
  def repository_created(identifier, vendor, url)
    project = Project.find_by_identifier(identifier)
    # Do not create the repository if the project has already one
    return 0 unless project && project.repository.nil?
    logger.debug "Repository for #{project.name} was created"
    repository = Repository.factory(vendor, :project => project, :url => url)
    repository.save
    repository.id || 0
  end

protected

  def check_enabled(name, args)
    Setting.sys_api_enabled?
  end
end
