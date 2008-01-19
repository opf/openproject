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

class VersionsController < ApplicationController
  layout 'base'
  menu_item :roadmap
  before_filter :find_project, :authorize

  cache_sweeper :version_sweeper, :only => [ :edit, :destroy ]
  
  def show
  end
  
  def edit
    if request.post? and @version.update_attributes(params[:version])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
    end
  end

  def destroy
    @version.destroy
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
  rescue
    flash[:error] = "Unable to delete version"
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
  end

  def download
    @attachment = @version.attachments.find(params[:attachment_id])
    @attachment.increment_download
    send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                    :type => @attachment.content_type
  rescue
    render_404
  end 
  
  def destroy_file
    @version.attachments.find(params[:attachment_id]).destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'projects', :action => 'list_files', :id => @project
  end
  
  def status_by
    respond_to do |format|
      format.html { render :action => 'show' }
      format.js { render(:update) {|page| page.replace_html 'status_by', render_issue_status_by(@version, params[:status_by])} }
    end
  end

private
  def find_project
    @version = Version.find(params[:id])
    @project = @version.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end
