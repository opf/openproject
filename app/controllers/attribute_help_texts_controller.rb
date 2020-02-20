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

class AttributeHelpTextsController < ApplicationController
  layout 'admin'
  menu_item :attribute_help_texts

  before_action :require_admin
  before_action :find_entry, only: %i(edit update destroy)
  before_action :find_type_scope
  before_action :require_enterprise_token_grant

  def new
    @attribute_help_text = AttributeHelpText.new type: @attribute_scope
  end

  def edit; end

  def update
    @attribute_help_text.attributes = permitted_params.attribute_help_text

    if @attribute_help_text.save
      flash[:notice] = t(:notice_successful_update)
      redirect_to attribute_help_texts_path(tab: @attribute_help_text.attribute_scope)
    else
      render action: 'edit'
    end
  end

  def create
    @attribute_help_text = AttributeHelpText.new permitted_params.attribute_help_text

    if @attribute_help_text.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to attribute_help_texts_path(tab: @attribute_help_text.attribute_scope)
    else
      render action: 'new'
    end
  end

  def destroy
    if @attribute_help_text.destroy
      flash[:notice] = t(:notice_successful_delete)
    else
      flash[:error] = t(:error_can_not_delete_entry)
    end

    redirect_to attribute_help_texts_path(tab: @attribute_help_text.attribute_scope)
  end

  def index
    @texts_by_type = AttributeHelpText.all_by_scope
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('attribute_help_texts.label_plural')
    else
      ActionController::Base.helpers.link_to(t('attribute_help_texts.label_plural'), attribute_help_texts_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  private

  def find_entry
    @attribute_help_text = AttributeHelpText.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_type_scope
    name = params.fetch(:name, 'WorkPackage')
    submodule = AttributeHelpText.available_types.find { |mod| mod == name }

    if submodule.nil?
      render_404
    end

    @attribute_scope = AttributeHelpText.const_get(submodule)
  end

  def require_enterprise_token_grant
    render_404 unless EnterpriseToken.allows_to?(:attribute_help_texts)
  end
end
