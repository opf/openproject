# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Users::DeletePageHeaderComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include ApplicationHelper

  def initialize(user:, layout:)
    super
    @user = user
    @layout = layout
  end

  def breadcrumb_items
    if @layout == "my"
      [{ href: my_account_path, text: t(:label_my_account) }, t("account.delete")]
    else
      [{ href: admin_index_path, text: t(:label_administration) },
       { href: admin_settings_users_path, text: t(:label_user_and_permission) },
       { href: users_path, text: t(:label_user_plural) },
       { href: edit_user_path(@user), text: @user.name },
       t("account.delete")]
    end
  end
end
