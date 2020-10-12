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

module Pages
  class Page
    include Capybara::DSL
    include RSpec::Matchers
    include OpenProject::StaticRouting::UrlHelpers

    def current_page?
      URI.parse(current_url).path == path
    end

    def visit!
      raise 'No path defined' unless path

      visit path

      self
    end

    def accept_alert_dialog!
      alert_dialog.accept if selenium_driver?
    end

    def dismiss_alert_dialog!
      alert_dialog.dismiss if selenium_driver?
    end

    def alert_dialog
      page.driver.browser.switch_to.alert
    end

    def has_alert_dialog?
      if selenium_driver?
        begin
          page.driver.browser.switch_to.alert
        rescue ::Selenium::WebDriver::Error::NoSuchAlertError
          false
        end
      end
    end

    def selenium_driver?
      Capybara.current_driver.to_s.include?('headless')
    end

    def set_items_per_page!(n)
      Setting.per_page_options = "#{n}, 50, 100"
    end

    def expect_current_path(query_params = nil)
      uri = URI.parse(current_url)
      current_path = uri.path
      current_path += '?' + uri.query if uri.query

      expected_path = path
      expected_path += "?#{query_params}" if query_params

      expect(current_path).to eql expected_path
    end

    def expect_notification(type: :success, message:)
      if notification_type == :angular
        expect(page).to have_selector(".notification-box.-#{type}", text: message, wait: 20)
      elsif type == :error
        expect(page).to have_selector(".errorExplanation", text: message)
      elsif type == :success
        expect(page).to have_selector(".flash.notice", text: message)
      else
        raise NotImplementedError
      end
    end

    def expect_and_dismiss_notification(type: :success, message:)
      expect_notification(type: type, message: message)
      dismiss_notification!
      expect_no_notification(type: type, message: message)
    end

    def dismiss_notification!
      page.find('.notification-box--close').click
    end

    def expect_no_notification(type: :success, message: nil)
      if type.nil?
        expect(page).to have_no_selector(".notification-box")
      else
        expect(page).to have_no_selector(".notification-box.-#{type}", text: message)
      end
    end

    def path
      nil
    end

    def notification_type
      :angular
    end
  end
end
