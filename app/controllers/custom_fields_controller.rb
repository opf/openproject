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

class CustomFieldsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :blank_translation_attributes_as_nil, :only => [:new, :edit]

  def index
    @custom_fields_by_type = CustomField.find(:all).group_by {|f| f.class.name }
    @tab = params[:tab] || 'WorkPackageCustomField'
  end

  def new
    @custom_field = begin
      if params[:type].to_s.match(/.+CustomField\z/)
        klass = params[:type].to_s.constantize
        klass.new(params[:custom_field]) if klass.ancestors.include? CustomField
      end
    rescue
    end
    (redirect_to(:action => 'index'); return) unless @custom_field

    if request.post? and @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @types = Type.find(:all, :order => 'position')
    end
  end

  def edit
    @custom_field = CustomField.find(params[:id])
    if request.put? and @custom_field.update_attributes(params[:custom_field])
      flash[:notice] = l(:notice_successful_update)
      call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
      redirect_to :action => 'index', :tab => @custom_field.class.name
    else
      @types = Type.find(:all, :order => 'position')
    end
  end

  def destroy
    @custom_field = CustomField.find(params[:id]).destroy
    redirect_to :action => 'index', :tab => @custom_field.class.name
  rescue
    flash[:error] = l(:error_can_not_delete_custom_field)
    redirect_to :action => 'index'
  end

  private

  def blank_translation_attributes_as_nil
    return unless params['custom_field'] && params['custom_field']['translations_attributes']

    params['custom_field']['translations_attributes'].each do |index, attributes|
      attributes.each do |key, value|
        attributes[key] = nil if value.blank?
      end
    end
  end
end
