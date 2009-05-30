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

class EnumerationsController < ApplicationController
  before_filter :require_admin
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
  end

  def new
    begin
      @enumeration = params[:type].constantize.new
    rescue NameError
      @enumeration = Enumeration.new      
    end
  end

  def create
    @enumeration = Enumeration.new(params[:enumeration])
    @enumeration.type = params[:enumeration][:type]
    if @enumeration.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'new'
    end
  end

  def edit
    @enumeration = Enumeration.find(params[:id])
  end

  def update
    @enumeration = Enumeration.find(params[:id])
    @enumeration.type = params[:enumeration][:type] if params[:enumeration][:type]
    if @enumeration.update_attributes(params[:enumeration])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @enumeration = Enumeration.find(params[:id])
    if !@enumeration.in_use?
      # No associated objects
      @enumeration.destroy
      redirect_to :action => 'index'
    elsif params[:reassign_to_id]
      if reassign_to = Enumeration.find_by_type_and_id(@enumeration.type, params[:reassign_to_id])
        @enumeration.destroy(reassign_to)
        redirect_to :action => 'index'
      end
    end
    @enumerations = Enumeration.find(:all, :conditions => ['type = (?)', @enumeration.type]) - [@enumeration]
  #rescue
  #  flash[:error] = 'Unable to delete enumeration'
  #  redirect_to :action => 'index'
  end
end
