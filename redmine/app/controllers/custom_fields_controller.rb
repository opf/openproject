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
    @custom_field_pages, @custom_fields = paginate :custom_fields, :per_page => 10
  end

  def new
    if request.get?
      @custom_field = CustomField.new
    else
      @custom_field = CustomField.new(params[:custom_field])
      if @custom_field.save
        flash[:notice] = 'CustomField was successfully created.'
        redirect_to :action => 'list'
      end
    end
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if request.post? and @custom_field.update_attributes(params[:custom_field])
      flash[:notice] = 'CustomField was successfully updated.'
      redirect_to :action => 'list'
    end
  end

  def destroy
    CustomField.find(params[:id]).destroy
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unable to delete custom field"
    redirect_to :action => 'list'
  end
end
