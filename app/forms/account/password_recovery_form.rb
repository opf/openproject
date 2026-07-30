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

class Account::PasswordRecoveryForm < ApplicationForm
  form do |form|
    form.group(data: { controller: "password-requirements" }) do |group|
      group.text_field(
        name: :new_password,
        label: User.human_attribute_name(:new_password),
        type: :password,
        required: true,
        autocomplete: "new-password",
        caption: helpers.password_complexity_requirements,
        input_width: :large,
        data: { "password-requirements-target": "passwordInput" }
      )
      group.text_field(
        name: :new_password_confirmation,
        label: User.human_attribute_name(:password_confirmation),
        type: :password,
        required: true,
        autocomplete: "new-password",
        input_width: :large
      )
    end
    form.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
  end
end
