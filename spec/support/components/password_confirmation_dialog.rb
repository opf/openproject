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

module Components
  class PasswordConfirmationDialog
    include Capybara::DSL
    include RSpec::Matchers

    def initialize; end

    def confirm_flow_with(password, should_fail: false)
      expect_open

      expect(submit_button).to be_disabled
      fill_in 'request_for_confirmation_password', with: password

      expect(submit_button).not_to be_disabled
      submit(should_fail)
    end

    def expect_open
      expect(page).to have_selector(selector)
    end

    def expect_closed
      expect(page).to have_no_selector(selector)
    end

    def submit_button
      page.find('.confirm-form-submit--continue')
    end

    private

    def selector
      '.password-confirm-dialog--modal'
    end

    def submit(should_fail)
      submit_button.click

      if should_fail
        expect(page).to have_selector('.flash.error',
                                      text: I18n.t(:notice_password_confirmation_failed))
      else
        expect(page).to have_no_selector('.flash.error')
      end
    end
  end
end
