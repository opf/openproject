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

class OnboardingController < ApplicationController
  no_authorization_required! :user_settings

  def user_settings
    @user = User.current

    result = Users::UpdateService
             .new(model: @user, user: @user)
             .call(permitted_params.user.to_h)

    if result.success?
      flash[:notice] = I18n.t(:notice_account_updated)
    end

    # Remove all query params:
    # the first_time_user param so that the modal is not shown again after redirect,
    # the welcome param so that the analytics is not fired again
    uri = Addressable::URI.parse(request.referer.to_s)
    uri.query_values = {}
    redirect_to uri.to_s
  end
end
