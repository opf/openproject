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

class CustomFieldsController < ApplicationController
  layout 'base'		
  before_filter :require_admin

  def index
    list
    render :action => 'list'
  end

  def list
    @custom_field_pages, @custom_fields = paginate :custom_fields, :per_page => 15
  end
  
  def new
    case params[:type]
      when "IssueCustomField" 
        @custom_field = IssueCustomField.new(params[:custom_field])
        @custom_field.trackers = Tracker.find(params[:tracker_ids]) if params[:tracker_ids]
      when "UserCustomField" 
        @custom_field = UserCustomField.new(params[:custom_field])
      when "ProjectCustomField" 
        @custom_field = ProjectCustomField.new(params[:custom_field])
      else
        redirect_to :action => 'list'
        return
    end  
    if request.post? and @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'list'
    end
    @trackers = Tracker.find(:all)
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if request.post? and @custom_field.update_attributes(params[:custom_field])
      if @custom_field.is_a? IssueCustomField
        @custom_field.trackers = params[:tracker_ids] ? Tracker.find(params[:tracker_ids]) : []
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list'
    end
    @trackers = Tracker.find(:all)
  end

  def destroy
    CustomField.find(params[:id]).destroy
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unable to delete custom field"
    redirect_to :action => 'list'
  end
end
