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

class OauthController < ApplicationController

  before_filter :require_login
  before_filter :app_template , only: [:index, :register]

  # Set 'my' page for account page
  layout 'my', only: :index
  menu_item :oauth_applications, only: :index
  before_filter :set_user , only: [:index]


  ##
  # List my OAuth grants and registered applications
  def index

    @grants = User.current.oauth_grants

    if User.current.admin?
      # Show all registered applications
      @applications = Doorkeeper::Application.all
      render locals: { show_owners: true }
    else
      @applications = User.current.oauth_applications
    end
  end

  def register
    if request.post?
      @new_app.attributes = oauth_application_params
      @new_app.owner = User.current
      if @new_app.save
        flash[:notice] = l(:notice_successful_create)
      end
    end

    redirect_to action: :index
  end

  # Destroy an oauth application
  def destroy_application
    @app = Doorkeeper::Application.find(params[:id])
    if @app.owner == User.current || User.current.admin?
      @app.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to action: :index
  end

  private

  def app_template
    @new_app = Doorkeeper::Application.new
  end

  ##
  # Sets @user for the 'my'-layout
  def set_user
    @user = User.current
  end

  def oauth_application_params
    params.require(:doorkeeper_application).permit(:name, :redirect_uri)
  end

end
