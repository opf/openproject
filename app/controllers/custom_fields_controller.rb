# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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
  before_filter :require_admin

  def index
    @custom_fields_by_type = CustomField.find(:all).group_by {|f| f.class.name }
    @tab = params[:tab] || 'IssueCustomField'
  end
  
  def new
    @custom_field = begin
      if params[:type].to_s.match(/.+CustomField$/)
        params[:type].to_s.constantize.new(params[:custom_field])
      end
    rescue
    end
    redirect_to(:action => 'index') and return unless @custom_field.is_a?(CustomField)
    
    if request.post? and @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    end
    @trackers = Tracker.find(:all, :order => 'position')
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if request.post? and @custom_field.update_attributes(params[:custom_field])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    end
    @trackers = Tracker.find(:all, :order => 'position')
  end
  
  def destroy
    @custom_field = CustomField.find(params[:id]).destroy
    redirect_to :action => 'index', :tab => @custom_field.class.name
  rescue
    flash[:error] = "Unable to delete custom field"
    redirect_to :action => 'index'
  end
end
