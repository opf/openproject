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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ErrorsController < ApplicationController
  include ErrorsHelper
  include OpenProjectErrorHelper
  include Accounts::CurrentUser

  no_authorization_required! :not_found, :unacceptable, :internal_error
  skip_before_action :check_if_login_required

  def not_found
    render_404
  end

  # this may be called on CSRF validation failure
  def unacceptable
    render file: "#{Rails.public_path.join('422.html')}",
           status: :unprocessable_entity,
           layout: false
  end

  def internal_error
    render_500 error_options
  end

  private

  def error_options
    {
      exception: request.env["action_dispatch.exception"]
    }.compact
  end

  def use_layout
    "only_logo"
  end
end
