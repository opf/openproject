#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  layout 'admin'
  menu_item :custom_style

  before_action :require_admin,
                except: %i[logo_download export_logo_download export_cover_download favicon_download touch_icon_download]
  before_action :require_ee_token,
                except: %i[upsale logo_download export_logo_download export_cover_download favicon_download touch_icon_download]
  skip_before_action :check_if_login_required,
                     only: %i[logo_download export_logo_download export_cover_download favicon_download touch_icon_download]

  def show
    @custom_style = CustomStyle.current || CustomStyle.new
    @current_theme = @custom_style.theme
    @theme_options = options_for_theme_select
  end

  def upsale; end

  def create
    @custom_style = CustomStyle.create(custom_style_params)
    if @custom_style.valid?
      redirect_to custom_style_path
    else
      flash[:error] = @custom_style.errors.full_messages
      render action: :show
    end
  end

  def update
    @custom_style = get_or_create_custom_style
    if @custom_style.update(custom_style_params)
      redirect_to custom_style_path
    else
      flash[:error] = @custom_style.errors.full_messages
      render action: :show
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

  def export_logo_download
    file_download(:export_logo_path)
  end

  def export_cover_download
    file_download(:export_cover_path)
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

  def export_logo_delete
    file_delete(:remove_export_logo)
  end

  def export_cover_delete
    file_delete(:remove_export_cover)
  end

  def favicon_delete
    file_delete(:remove_favicon)
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
    theme = OpenProject::CustomStyles::ColorThemes.themes.find { |t| t[:theme] == params[:theme] }

    call = ::Design::UpdateDesignService
      .new(theme)
      .call

    call.on_success do
      flash[:notice] = I18n.t(:notice_successful_update)
    end

    call.on_failure do
      flash[:error] = call.message
    end

    redirect_to action: :show
  end

  def show_local_breadcrumb
    true
  end

  private

  def options_for_theme_select
    options = OpenProject::CustomStyles::ColorThemes.themes.pluck(:theme)
    unless @current_theme.present?
      options << [t('admin.custom_styles.color_theme_custom'), '',
                  { selected: true, disabled: true }]
    end

    options
  end

  def get_or_create_custom_style
    CustomStyle.current || CustomStyle.create!
  end

  def require_ee_token
    unless EnterpriseToken.allows_to?(:define_custom_style)
      redirect_to custom_style_upsale_path
    end
  end

  def custom_style_params
    params.require(:custom_style).permit(:logo, :remove_logo,
                                         :export_logo, :remove_export_logo,
                                         :export_cover, :remove_export_cover,
                                         :export_cover_text_color,
                                         :favicon, :remove_favicon,
                                         :touch_icon, :remove_touch_icon)
  end

  def file_download(path_method)
    @custom_style = CustomStyle.current
    if @custom_style && @custom_style.send(path_method)
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

    @custom_style.send(remove_method)
    @custom_style.save
    redirect_to custom_style_path
  end
end
