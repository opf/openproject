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

require "support/pages/page"

module Pages
  module My
    class Password < ::Pages::Page
      def path
        "/my/password"
      end

      def change_password(old_password, new_password, confirmation = new_password)
        SeleniumHubWaiter.wait
        page.fill_in("password", with: old_password, match: :prefer_exact)
        page.fill_in("new_password", with: new_password)
        page.fill_in("new_password_confirmation", with: confirmation)

        page.click_button "Change password"
      end

      def expect_password_reuse_error_message(count)
        expect_flash(type: :error,
                     message: I18n.t(:"activerecord.errors.models.user.attributes.password.reused", count:))
      end

      def expect_password_weak_error_message
        expect_flash(type: :error,
                     message: "Password Must include characters of the following types")
      end

      def expect_password_updated_message
        expect_and_dismiss_flash(type: :info, message: I18n.t(:notice_account_password_updated))
      end
    end
  end
end
