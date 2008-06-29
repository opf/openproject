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

class WatchersController < ApplicationController
  layout 'base'
  before_filter :require_login, :find_project, :check_project_privacy
  
  def add
    user = User.current
    @watched.add_watcher(user)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render(:update) {|page| page.replace_html 'watcher', watcher_link(@watched, user)} }
    end
  rescue RedirectBackError
    render :text => 'Watcher added.', :layout => true
  end
  
  def remove
    user = User.current
    @watched.remove_watcher(user)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render(:update) {|page| page.replace_html 'watcher', watcher_link(@watched, user)} }
    end
  rescue RedirectBackError
    render :text => 'Watcher removed.', :layout => true
  end

private
  def find_project
    klass = Object.const_get(params[:object_type].camelcase)
    return false unless klass.respond_to?('watched_by')
    @watched = klass.find(params[:object_id])
    @project = @watched.project
  rescue
    render_404
  end
end
