#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class EnumerationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  include CustomFieldsHelper

  def index
  end

  def new
    begin
      klass = params[:type].constantize
      raise NameError unless klass.ancestors.include? Enumeration
      @enumeration = klass.new
    rescue NameError
      @enumeration = Enumeration.new
    end
  end

  def create
    @enumeration = Enumeration.new do |e|
      e.type = params[:enumeration].delete(:type)
      e.attributes = params[:enumeration]
    end

    if @enumeration.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index', :type => @enumeration.type
    else
      render :action => 'new'
    end
  end

  def edit
    @enumeration = Enumeration.find(params[:id])
  end

  def update
    @enumeration = Enumeration.find(params[:id])
    @enumeration.type = params[:enumeration].delete(:type) if params[:enumeration][:type]
    if @enumeration.update_attributes(params[:enumeration])
      flash[:notice] = l(:notice_successful_update)
      redirect_to enumerations_path(:type => @enumeration.type)
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
      return
    elsif params[:reassign_to_id]
      if reassign_to = @enumeration.class.find_by_id(params[:reassign_to_id])
        @enumeration.destroy(reassign_to)
        redirect_to :action => 'index'
        return
      end
    end
    @enumerations = @enumeration.class.find(:all) - [@enumeration]
  end

  def default_breadcrumb
    l(:label_enumerations)
  end
end
