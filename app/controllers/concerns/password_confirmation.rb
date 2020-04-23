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

##
# Acts as a filter for actions that require password confirmation to have
# passed before it may be accessed.
module PasswordConfirmation
  def check_password_confirmation
    return true unless password_confirmation_required?

    password = params[:_password_confirmation]
    return true if password.present? && current_user.check_password?(password)

    flash[:error] = I18n.t(:notice_password_confirmation_failed)
    redirect_back fallback_location: back_url
    false
  end

  ##
  # Returns whether password confirmation has been enabled globally
  # AND the current user is internally authenticated.
  def password_confirmation_required?
    OpenProject::Configuration.internal_password_confirmation? &&
      !User.current.uses_external_authentication?
  end
end
