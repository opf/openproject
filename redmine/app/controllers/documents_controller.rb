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

class DocumentsController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize

  def show
    @attachments = @document.attachments.find(:all, :order => "created_on DESC")
  end

  def edit
    @categories = Enumeration::get_values('DCAT')
    if request.post? and @document.update_attributes(params[:document])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @document
    end
  end  

  def destroy
    @document.destroy
    redirect_to :controller => 'projects', :action => 'list_documents', :id => @project
  end

  def download
    @attachment = @document.attachments.find(params[:attachment_id])
    @attachment.increment_download
    send_file @attachment.diskfile, :filename => @attachment.filename
  end 
  
  def add_attachment
    # Save the attachment
    if params[:attachment][:file].size > 0
      @attachment = @document.attachments.build(params[:attachment])      
      @attachment.author_id = self.logged_in_user.id if self.logged_in_user
      @attachment.save
    end
    redirect_to :action => 'show', :id => @document
  end
  
  def destroy_attachment
    @document.attachments.find(params[:attachment_id]).destroy
    redirect_to :action => 'show', :id => @document
  end

private
  def find_project
    @document = Document.find(params[:id])
    @project = @document.project
  end  
end
