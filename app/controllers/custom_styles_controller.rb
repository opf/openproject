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

class CustomStylesController < ApplicationController

  def css
    logo_styles = ''
    if @custom_style = CustomStyle.current
      logo_styles = %{
  margin: 0px;
  width: 230px;
  height: 55px;
  background-image: url(\"#{custom_styles_logo_path(digest: @custom_style.digest, filename: @custom_style.logo_identifier)}\");
  background-repeat: no-repeat;
  background-position-x: 0px;
  background-position-y: 0px;
  background-size: cover;
}
    end
    css_body = "#logo .home-link {#{logo_styles}}"
    render :plain => css_body, :content_type => Mime::CSS
  end

  def create
    if @custom_style = CustomStyle.create(custom_style_params)

    else

    end
    redirect_to controller: :settings, action: :edit, tab: :display
  end

  def update
    @custom_style = CustomStyle.current
    @custom_style.update_attributes(custom_style_params)
    redirect_to controller: :settings, action: :edit, tab: :display
  end

  def logo_download
    @custom_style = CustomStyle.current
    if @custom_style && @custom_style.logo
      send_file(@custom_style.logo_url)
    else
      head :not_found
    end
  end

  def logo_delete
    @custom_style = CustomStyle.current
    @custom_style.remove_logo!
    @custom_style.save
    head :ok
  end

  private
    def custom_style_params
      params.require(:custom_style).permit(:logo, :remove_logo)
    end
end
