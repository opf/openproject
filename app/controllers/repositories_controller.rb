# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class RepositoriesController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize

  def show
    @entries = @repository.scm.entries('')
    show_error and return unless @entries
    @latest_revision = @entries.revisions.latest
  end
  
  def browse
    @entries = @repository.scm.entries(@path, @rev)
    show_error and return unless @entries
  end
  
  def revisions
    @entry = @repository.scm.entry(@path, @rev)
    @revisions = @repository.scm.revisions(@path, @rev)
    show_error and return unless @entry && @revisions
  end
  
  def entry
    if 'raw' == params[:format]
      content = @repository.scm.cat(@path, @rev)
      show_error and return unless content
      send_data content, :filename => @path.split('/').last
    end
  end
  
  def revision
    @revisions = @repository.scm.revisions '', @rev, @rev, :with_paths => true
    show_error and return unless @revisions
    @revision = @revisions.first  
  end
  
  def diff
    @rev_to = params[:rev_to] || (@rev-1)
    @diff = @repository.scm.diff(params[:path], @rev, @rev_to)
    show_error and return unless @diff
  end
  
private
  def find_project
    @project = Project.find(params[:id])
    @repository = @project.repository
    render_404 and return false unless @repository
    @path = params[:path].squeeze('/').gsub(/^\//, '') if params[:path]
    @path ||= ''
    @rev = params[:rev].to_i if params[:rev] and params[:rev].to_i > 0
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show_error
    flash.now[:notice] = l(:notice_scm_error)
    render :nothing => true, :layout => true
  end
end
