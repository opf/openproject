# frozen_string_literal: true

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

class CustomStylesController < ApplicationController
  include EnterpriseHelper
  include CustomStylesControllerHelper

  layout "admin"
  menu_item :custom_style

  UNGUARDED_ACTIONS = %i[logo_download
                         logo_mobile_download
                         favicon_download
                         touch_icon_download].freeze

  before_action :require_admin,
                except: UNGUARDED_ACTIONS
  skip_before_action :check_if_login_required,
                     only: UNGUARDED_ACTIONS
  no_authorization_required! *UNGUARDED_ACTIONS

  guard_enterprise_feature(:define_custom_style, except: UNGUARDED_ACTIONS + %i[show])

  def default_url_options
    super.merge(tab: params[:tab])
  end

  def show
    @custom_style = CustomStyle.current || CustomStyle.new
    @current_theme = @custom_style.theme
    @theme_options = options_for_theme_select

    if params[:tab].blank?
      redirect_to tab: "interface"
    end
  end

  def upsell; end

  def create
    @custom_style = CustomStyle.create(custom_style_params)
    if @custom_style.valid?
      redirect_to custom_style_path
    else
      flash[:error] = @custom_style.errors.full_messages
      render action: :show, status: :unprocessable_entity
    end
  end

  def update
    flash.clear
    @custom_style = get_or_create_custom_style
    parameters = custom_style_params
    error = validate_font_uploads(parameters)
    if !error && @custom_style.update(parameters)
      redirect_to custom_style_path
    else
      flash[:error] = error || @custom_style.errors.full_messages
      render action: :show, status: :unprocessable_entity
    end
  end

  def update_export_cover_text_color
    @custom_style = get_or_create_custom_style
    color = params[:export_cover_text_color]
    color_hexcode_regex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
    color = nil if color.blank?
    if color.nil? || color.match(color_hexcode_regex)
      @custom_style.export_cover_text_color = color
      @custom_style.save
    end
    redirect_to custom_style_path
  end

  def logo_download
    file_download(:logo_path)
  end

  def logo_mobile_download
    file_download(:logo_mobile_path)
  end

  def export_logo_download
    file_download(:export_logo_path)
  end

  def export_cover_download
    file_download(:export_cover_path)
  end

  def export_footer_download
    file_download(:export_footer_path)
  end

  def favicon_download
    file_download(:favicon_path)
  end

  def touch_icon_download
    file_download(:touch_icon_path)
  end

  def logo_delete
    file_delete(:remove_logo)
  end

  def logo_mobile_delete
    file_delete(:remove_logo_mobile)
  end

  def export_logo_delete
    file_delete(:remove_export_logo)
  end

  def export_cover_delete
    file_delete(:remove_export_cover)
  end

  def export_footer_delete
    file_delete(:remove_export_footer)
  end

  def favicon_delete
    file_delete(:remove_favicon)
  end

  def export_font_regular_delete
    file_delete(:remove_export_font_regular)
  end

  def export_font_bold_delete
    file_delete(:remove_export_font_bold)
  end

  def export_font_italic_delete
    file_delete(:remove_export_font_italic)
  end

  def export_font_bold_italic_delete
    file_delete(:remove_export_font_bold_italic)
  end

  def touch_icon_delete
    file_delete(:remove_touch_icon)
  end

  def update_colors
    variable_params = params[:design_colors].first

    ::Design::UpdateDesignService
      .new(colors: variable_params, theme: params[:theme])
      .call

    redirect_to action: :show
  end

  def update_themes
    call = ::Design::UpdateDesignService
       .new(theme_from_params)
       .call

    call.on_success do
      flash[:notice] = I18n.t(:notice_successful_update)
    end

    call.on_failure do
      flash[:error] = call.message
    end

    redirect_to custom_style_path
  end

  def export_demo_pdf_download
    result = ::Exports::PDF::DemoGenerator.new.export!
    expires_in 0, public: false
    send_data result.content,
              filename: result.title,
              type: "application/pdf",
              disposition: "inline"
  rescue StandardError => e
    Rails.logger.error "Failed to generate demo PDF: #{e.message}"
    flash[:error] = e.message
    redirect_to custom_style_path
  end

  private

  def theme_from_params
    OpenProject::CustomStyles::ColorThemes.themes.find { |t| t[:theme] == params[:theme] }
  end

  def options_for_theme_select
    options = OpenProject::CustomStyles::ColorThemes.themes.pluck(:theme)
    unless @current_theme.present?
      options << [t("admin.custom_styles.color_theme_custom"), "",
                  { selected: true, disabled: true }]
    end

    options
  end

  def get_or_create_custom_style
    CustomStyle.current || CustomStyle.create!
  end

  def custom_style_params
    params.expect(custom_style: %i[
                    logo remove_logo
                    logo_mobile remove_logo_mobile
                    export_logo remove_export_logo
                    export_cover remove_export_cover
                    export_footer remove_export_footer
                    favicon remove_favicon
                    touch_icon remove_touch_icon
                    export_font_regular remove_export_font_regular
                    export_font_bold remove_export_font_bold
                    export_font_italic remove_export_font_italic
                    export_font_bold_italic remove_export_font_bold_italic
                    export_cover_text_color
                  ])
  end

  def file_download(path_method)
    @custom_style = CustomStyle.current
    if @custom_style&.send(path_method)
      expires_in 1.year, public: true, must_revalidate: false
      send_file(@custom_style.send(path_method))
    else
      head :not_found
    end
  end

  def file_delete(remove_method)
    @custom_style = CustomStyle.current
    if @custom_style.nil?
      return render_404
    end

    @custom_style.send("#{remove_method}!")
    redirect_to custom_style_path, status: :see_other
  end
end
