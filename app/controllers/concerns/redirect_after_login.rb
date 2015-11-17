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

##
# Intended to be used by the AccountController to decide where to
# send the user when they logged in.
module Concerns::RedirectAfterLogin
  def redirect_after_login(user)
    if user.first_login
      user.update_attribute(:first_login, false)

      welcome_redirect
    else
      default_redirect
    end
  end

  #    * * *

  def welcome_redirect
    project = welcome_project

    if project && redirect_to_welcome_project?(current_user, project)
      redirect_to welcome_redirect_url(project)
    else
      default_redirect
    end
  end

  def welcome_redirect_url(project)
    url_for controller: :work_packages, project_id: project.identifier
  end

  ##
  # Only the first user as the creator of the OpenProject installation is
  # supposed to be redirected like this.
  def redirect_to_welcome_project?(user, _project)
    User.not_builtin.count == 1 && user.admin?
  end

  def welcome_project
    DemoData::ProjectSeeder::Data.find_demo_project
  end

  def default_redirect
    redirect_back_or_default controller: '/my', action: 'page'
  end
end
