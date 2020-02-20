#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CustomFieldsController < ApplicationController
  layout 'admin'

  helper_method :gon

  before_action :require_admin
  before_action :find_custom_field, only: %i(edit update destroy move delete_option)
  before_action :prepare_custom_option_position, only: %i(update create)
  before_action :find_custom_option, only: :delete_option

  def index
    # loading wp cfs exclicity to allow for eager loading
    @custom_fields_by_type = CustomField.all.where.not(type: 'WorkPackageCustomField').group_by { |f| f.class.name }
    @custom_fields_by_type['WorkPackageCustomField'] = WorkPackageCustomField.includes(:types).all

    @tab = params[:tab] || 'WorkPackageCustomField'
  end

  def new
    @custom_field = careful_new_custom_field permitted_params.custom_field_type
  end

  def create
    @custom_field = careful_new_custom_field permitted_params.custom_field_type, get_custom_field_params

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
    @custom_field.attributes = get_custom_field_params

    if @custom_field.save
      flash[:notice] = t(:notice_successful_update)
      call_hook(:controller_custom_fields_edit_after_save, custom_field: @custom_field)
      redirect_back_or_default edit_custom_field_path(id: @custom_field.id)
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

  def delete_option
    if @custom_option.destroy
      num_deleted = delete_custom_values! @custom_option

      flash[:notice] = I18n.t(
        :notice_custom_options_deleted, option_value: @custom_option.value, num_deleted: num_deleted
      )
    else
      flash[:error] = @custom_option.errors.full_messages
    end

    redirect_to edit_custom_field_path(id: @custom_field.id)
  end

  private

  def get_custom_field_params
    custom_field_params = permitted_params.custom_field

    if !EnterpriseToken.allows_to?(:multiselect_custom_fields)
      custom_field_params.delete :multi_value
    end

    custom_field_params
  end

  def find_custom_option
    @custom_option = CustomOption.find params[:option_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def delete_custom_values!(custom_option)
    CustomValue
      .where(custom_field_id: custom_option.custom_field_id, value: custom_option.id)
      .delete_all
  end

  def prepare_custom_option_position
    return unless params[:custom_field][:custom_options_attributes]

    index = 0

    params[:custom_field][:custom_options_attributes].each do |_id, attributes|
      attributes[:position] = (index = index + 1)
    end
  end

  def careful_new_custom_field(type, params = {})
    cf = begin
      if type.to_s =~ /.+CustomField\z/
        klass = type.to_s.constantize
        klass.new(params) if klass.ancestors.include? CustomField
      end
    rescue NameError => e
      Rails.logger.error "#{e.message}:\n#{e.backtrace.join("\n")}"
      nil
    end
    redirect_to custom_fields_path unless cf
    cf
  end

  def find_custom_field
    @custom_field = CustomField.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('label_custom_field_plural')
    else
      ActionController::Base.helpers.link_to(t('label_custom_field_plural'), custom_fields_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
