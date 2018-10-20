#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class CustomStylesController < ApplicationController
  layout 'admin'
  menu_item :custom_style

  before_action :require_admin, except: [:logo_download, :favicon_download, :touch_icon_download]
  before_action :require_ee_token, except: [:upsale, :logo_download, :favicon_download, :touch_icon_download]
  skip_before_action :check_if_login_required, only: [:logo_download, :favicon_download, :touch_icon_download]

  def show
    @custom_style = CustomStyle.current || CustomStyle.new
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
    @custom_style = CustomStyle.current
    if @custom_style.update_attributes(custom_style_params)
      redirect_to custom_style_path
    else
      flash[:error] = @custom_style.errors.full_messages
      render action: :show
    end
  end

  def logo_download
    file_download(:logo_path)
  end

  def favicon_download
    file_download(:favicon_path)
  end

  def touch_icon_download
    file_download(:touch_icon_path)
  end

  def logo_delete
    file_delete(:remove_logo!)
  end

  def favicon_delete
    file_delete(:remove_favicon!)
  end

  def touch_icon_delete
    file_delete(:remove_touch_icon!)
  end

  def update_colors
    variable_params = params[:design_colors].first

    variable_params.each do |param_variable, param_hexcode|
      if design_color = DesignColor.find_by(variable: param_variable)
        if param_hexcode.blank?
          design_color.destroy
        elsif design_color.hexcode != param_hexcode
          design_color.hexcode = param_hexcode
          design_color.save
        end
      else
        # create that design_color
        design_color = DesignColor.new variable: param_variable, hexcode: param_hexcode
        design_color.save
      end
    end

    redirect_to action: :show
  end

  def show_local_breadcrumb
    true
  end

  private

  def require_ee_token
    unless EnterpriseToken.allows_to?(:define_custom_style)
      redirect_to custom_style_upsale_path
    end
  end

  def custom_style_params
    params.require(:custom_style).permit(:logo, :remove_logo, :favicon, :remove_favicon, :touch_icon, :remove_touch_icon)
  end

  def file_download(path_method)
    @custom_style = CustomStyle.current
    if @custom_style && @custom_style.send(path_method)
      expires_in 1.years, public: true, must_revalidate: false
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
