#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class AttributeHelpTextsController < ApplicationController
  layout "admin"
  menu_item :attribute_help_texts

  before_action :authorize_global
  before_action :find_entry, only: %i(edit update destroy)
  before_action :find_type_scope

  def index
    @texts_by_type = AttributeHelpText.all_by_scope
  end

  def new
    @attribute_help_text = AttributeHelpText.new type: @attribute_scope
  end

  def edit; end

  def create
    call = ::AttributeHelpTexts::CreateService
      .new(user: current_user)
      .call(permitted_params_with_attachments)

    if call.success?
      flash[:notice] = t(:notice_successful_create)
      redirect_to attribute_help_texts_path(tab: call.result.attribute_scope)
    else
      @attribute_help_text = call.result
      flash[:error] = call.message || I18n.t("notice_internal_server_error")
      render action: "new"
    end
  end

  def update
    call = ::AttributeHelpTexts::UpdateService
      .new(user: current_user, model: @attribute_help_text)
      .call(permitted_params_with_attachments)

    if call.success?
      flash[:notice] = t(:notice_successful_update)
      redirect_to attribute_help_texts_path(tab: @attribute_help_text.attribute_scope)
    else
      flash[:error] = call.message || I18n.t("notice_internal_server_error")
      render action: "edit"
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

  protected

  def default_breadcrumb; end

  def show_local_breadcrumb
    false
  end

  private

  def permitted_params_with_attachments
    permitted_params.attribute_help_text.merge(attachment_params)
  end

  def attachment_params
    attachment_params = permitted_params.attachments.to_h

    if attachment_params.any?
      { attachment_ids: attachment_params.values.map(&:values).flatten }
    else
      {}
    end
  end

  def find_entry
    @attribute_help_text = AttributeHelpText.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_type_scope
    name = params.fetch(:name, "WorkPackage")
    submodule = AttributeHelpText.available_types.find { |mod| mod == name }

    if submodule.nil?
      render_404
    end

    @attribute_scope = AttributeHelpText.const_get(submodule)
  end
end
