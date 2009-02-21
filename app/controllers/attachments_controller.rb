# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class AttachmentsController < ApplicationController
  before_filter :find_project
  before_filter :read_authorize, :except => :destroy
  before_filter :delete_authorize, :only => :destroy
  
  verify :method => :post, :only => :destroy
  
  def show
    if @attachment.is_diff?
      @diff = File.new(@attachment.diskfile, "rb").read
      render :action => 'diff'
    elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
      @content = File.new(@attachment.diskfile, "rb").read
      render :action => 'file'
    else
      download
    end
  end
  
  def download
    if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
      @attachment.increment_download
    end
    
    # images are sent inline
    send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                    :type => @attachment.content_type, 
                                    :disposition => (@attachment.image? ? 'inline' : 'attachment')
   
  end
  
  def destroy
    # Make sure association callbacks are called
    @attachment.container.attachments.delete(@attachment)
    redirect_to :back
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'projects', :action => 'show', :id => @project
  end
  
private
  def find_project
    @attachment = Attachment.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def read_authorize
    @attachment.visible? ? true : deny_access
  end
  
  def delete_authorize
    @attachment.deletable? ? true : deny_access
  end
end
