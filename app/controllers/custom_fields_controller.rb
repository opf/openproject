#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
  before_filter :find_types, except: [:index, :destroy]
  before_filter :find_custom_field, only: [:edit, :update, :destroy, :move]
  before_filter :blank_translation_attributes_as_nil, only: [:create, :update]

  def index
    @custom_fields_by_type = CustomField.find(:all).group_by { |f| f.class.name }
    @tab = params[:tab] || 'WorkPackageCustomField'
  end

  def new
    @custom_field = careful_new_custom_field permitted_params.custom_field_type
  end

  def create
    @custom_field = careful_new_custom_field permitted_params.custom_field_type, @custom_field_params

    if @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, custom_field: @custom_field)
      redirect_to custom_fields_path(tab: @custom_field.class.name)
    else
      render action: 'new'
    end
  end

  def edit; end

  def update
    if @custom_field.update_attributes(@custom_field_params)
      flash[:notice] = l(:notice_successful_update)
      call_hook(:controller_custom_fields_edit_after_save, custom_field: @custom_field)
      redirect_to custom_fields_path(tab: @custom_field.class.name)
    else
      render action: 'edit'
    end
  end

  def destroy
    begin
      @custom_field.destroy
    rescue
      flash[:error] = l(:error_can_not_delete_custom_field)
    end
    redirect_to custom_fields_path(tab: @custom_field.class.name)
  end

  private

  def blank_translation_attributes_as_nil
    @custom_field_params = permitted_params.custom_field
    return unless @custom_field_params['translations_attributes']

    @custom_field_params['translations_attributes'].each do |_index, attributes|
      attributes.each do |key, value|
        attributes[key] = nil if value.blank?
      end
    end
  end

  def careful_new_custom_field(type, params = {})
    cf = begin
      if type.to_s.match(/.+CustomField\z/)
        klass = type.to_s.constantize
        klass.new(params) if klass.ancestors.include? CustomField
      end
    rescue
    end
    redirect_to custom_fields_path unless cf
    cf
  end

  def find_custom_field
    @custom_field = CustomField.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_types
    @types = Type.find(:all, order: 'position')
  end
end
