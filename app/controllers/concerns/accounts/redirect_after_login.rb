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

##
# Intended to be used by the AccountController to decide where to
# send the user when they logged in.
module Accounts::RedirectAfterLogin
  def redirect_after_login(user)
    if user.first_login
      user.update_attribute(:first_login, false)

      call_hook :user_first_login, { user: }

      first_login_redirect
    else
      default_redirect
    end
  end

  def default_redirect
    if (url = OpenProject::Configuration.after_login_default_redirect_url)
      redirect_back_or_default url
    else
      redirect_back_or_default my_page_path
    end
  end

  def first_login_redirect
    if (url = OpenProject::Configuration.after_first_login_redirect_url)
      redirect_back_or_default url
    else
      redirect_back_or_default home_url(first_time_user: true)
    end
  end
end
