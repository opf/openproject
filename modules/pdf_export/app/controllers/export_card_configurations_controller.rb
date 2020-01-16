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


class ExportCardConfigurationsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :load_config, only: [:show, :update, :edit, :destroy, :activate, :deactivate]
  before_action :load_configs, only: [:index]

  def index
  end

  def show
  end

  def edit
  end

  def new
    @config = ExportCardConfiguration.new
  end

  def create
    @config = ExportCardConfiguration.new(export_card_configurations_params)
    if @config.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render "new"
    end
  end

  def update
    if cannot_update_default
      flash[:error] = l(:error_can_not_change_name_of_default_configuration)
      render "edit"
    elsif @config.update(export_card_configurations_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render "edit"
    end
  end

  def destroy
    if !@config.is_default? && @config.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:error_can_not_delete_export_card_configuration)
    end
    redirect_to :action => 'index'
  end

  def activate
    if @config.activate
      flash[:notice] = l(:notice_export_card_configuration_activated)
    else
      flash[:notice] = l(:error_can_not_activate_export_card_configuration)
    end
    redirect_to :action => 'index'
  end

  def deactivate
    if @config.deactivate
      flash[:notice] = l(:notice_export_card_configuration_deactivated)
    else
      flash[:notice] = l(:error_can_not_deactivate_export_card_configuration)
    end
    redirect_to :action => 'index'
  end

  def show_local_breadcrumb
    true
  end

  private

  def cannot_update_default
    @config.is_default? && export_card_configurations_params[:name].downcase != "default"
  end

  def export_card_configurations_params
    params.require(:export_card_configuration).permit(:name, :rows, :per_page, :page_size, :orientation, :description)
  end

  def load_config
    @config = ExportCardConfiguration.find(params[:id])
  end

  def load_configs
    @configs = ExportCardConfiguration.all
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('label_export_card_configuration')
    else
      ActionController::Base.helpers.link_to(t('label_export_card_configuration'), pdf_export_export_card_configurations_path)
    end
  end
end
