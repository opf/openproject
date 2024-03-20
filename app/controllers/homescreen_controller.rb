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

class HomescreenController < ApplicationController
  skip_before_action :check_if_login_required, only: [:robots]

  layout 'global'

  def index
    @newest_projects = Project.visible.newest.take(3)
    @newest_users = User.active.newest.take(3)
    @news = News.latest(count: 3)
    @announcement = Announcement.active_and_current

    @homescreen = OpenProject::Static::Homescreen
  end

  current_menu_item [:index] do
    :home
  end

  def robots
    if Setting.login_required?
      render template: 'homescreen/robots-login-required', format: :text
    else
      @projects = Project.active.public_projects
    end
  end
end
