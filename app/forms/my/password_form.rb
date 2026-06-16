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

class My::PasswordForm < ApplicationForm
  def initialize(user:, back_url: nil, submit_button_scheme: :primary)
    super()
    @user = user
    @back_url = back_url
    @submit_button_scheme = submit_button_scheme
  end

  form do |f|
    f.fieldset_group(title: helpers.t(:label_change_password),
                     mt: 2) do |fg|
      fg.hidden(name: :back_url, value: @back_url) if @back_url.present?
      fg.hidden(name: :password_change_user, value: @user.login)

      fg.text_field(
        name: :password,
        type: :password,
        input_width: :medium,
        label: User.human_attribute_name(:current_password),
        required: true,
        autocomplete: "current-password"
      )

      fg.text_field(
        name: :new_password,
        type: :password,
        input_width: :medium,
        label: User.human_attribute_name(:new_password),
        required: true,
        autocomplete: "new-password",
        data: { "password-requirements-target": "passwordInput" }
      )

      fg.text_field(
        name: :new_password_confirmation,
        type: :password,
        input_width: :medium,
        label: User.human_attribute_name(:password_confirmation),
        required: true,
        autocomplete: "new-password"
      )

      fg.submit(name: :submit, label: helpers.t(:button_change_password), scheme: @submit_button_scheme)
    end
  end
end
