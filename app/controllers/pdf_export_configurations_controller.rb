#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class PdfExportConfigurationsController < ApplicationController
  include WorkPackage::PDFExport::Style
  layout 'admin'
  menu_item :pdf_export

  before_action :require_admin
  before_action :load_config, only: %i[show update edit destroy activate deactivate]
  before_action :load_configs, only: [:index]

  def index; end

  def show; end

  def new
    @config = PdfExportConfiguration.new(styles: standard_styles.to_yaml)
  end

  def edit; end

  def create
    @config = PdfExportConfiguration.new(pdf_export_configurations_params)
    if @config.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to action: 'index'
    else
      render "new"
    end
  end

  def update
    if @config.update(pdf_export_configurations_params)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: 'index'
    else
      render "edit"
    end
  end

  def destroy
    flash[:notice] = if !@config.is_default? && @config.destroy
                       I18n.t(:notice_successful_delete)
                     else
                       I18n.t(:error_can_not_delete_entry)
                     end
    redirect_to action: 'index'
  end

  def activate
    flash[:notice] = if @config.activate
                       I18n.t('pdf_export.settings.configuration_activated')
                     else
                       I18n.t('pdf_export.settings.error_can_not_activate_configuration')
                     end
    redirect_to action: 'index'
  end

  def deactivate
    flash[:notice] = if @config.deactivate
                       I18n.t('pdf_export.settings.configuration_deactivated')
                     else
                       I18n.t('pdf_export.settings.error_can_not_deactivate_configuration')
                     end
    redirect_to action: 'index'
  end

  def show_local_breadcrumb
    true
  end

  private

  def pdf_export_configurations_params
    params.require(:pdf_export_configuration).permit(:name, :styles, :description)
  end

  def load_config
    @config = PdfExportConfiguration.find(params[:id])
  end

  def load_configs
    @configs = PdfExportConfiguration.all
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      I18n.t('pdf_export.settings.configuration')
    else
      ActionController::Base.helpers.link_to(I18n.t('pdf_export.settings.configuration'), pdf_export_configurations_path)
    end
  end
end
