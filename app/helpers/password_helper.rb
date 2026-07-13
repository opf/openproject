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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module PasswordHelper
  include PasswordConfirmation

  ##
  # Decorate the form_for helper with the request-for-confirmation directive
  # when the user is internally authenticated.
  def password_confirmation_form_for(record, options = {}, &)
    if password_confirmation_required?
      options.reverse_merge!(html: {})
      data = options[:html].fetch(:data, {})
      options[:html][:data] = password_confirmation_data_attribute(data)
    end

    form_for(record, options, &)
  end

  def password_confirmation_data_attribute(with_data = {})
    controller = with_data.fetch(:controller, "")

    if password_confirmation_required?
      with_data.merge(controller: "#{controller} require-password-confirmation".strip)
    else
      with_data
    end
  end

  def render_password_complexity_hint
    render_password_requirements
  end
end
