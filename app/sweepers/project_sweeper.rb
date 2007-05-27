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

class ProjectSweeper < ActionController::Caching::Sweeper
  observe Project

  def before_save(project)
    if project.new_record?
      expire_cache_for(project.parent) if project.parent
    else
      project_before_update = Project.find(project.id)
      return if project_before_update.parent_id == project.parent_id && project_before_update.status == project.status
      expire_cache_for(project.parent) if project.parent      
      expire_cache_for(project_before_update.parent) if project_before_update.parent
    end
  end
  
  def after_destroy(project)
    expire_cache_for(project.parent) if project.parent
  end
          
private
  def expire_cache_for(project)
    expire_fragment(Regexp.new("projects/(calendar|gantt)/#{project.id}\\."))
  end
end
