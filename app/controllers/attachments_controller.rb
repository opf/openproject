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

class AttachmentsController < ApplicationController
  layout 'base'
  before_filter :find_project

  def show
    if @attachment.is_diff?
      @diff = File.new(@attachment.diskfile, "rb").read
      render :action => 'diff'
    elsif @attachment.is_text?
      @content = File.new(@attachment.diskfile, "rb").read
      render :action => 'file'
    elsif
      download
    end
  end
  
  def download
    @attachment.increment_download if @attachment.container.is_a?(Version)
    
    # images are sent inline
    send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                    :type => @attachment.content_type, 
                                    :disposition => (@attachment.image? ? 'inline' : 'attachment')
  end
 
private
  def find_project
    @attachment = Attachment.find(params[:id])
    @project = @attachment.project
    permission = @attachment.container.is_a?(Version) ? :view_files : "view_#{@attachment.container.class.name.underscore.pluralize}".to_sym
    allowed = User.current.allowed_to?(permission, @project)
    allowed ? true : (User.current.logged? ? render_403 : require_login)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
