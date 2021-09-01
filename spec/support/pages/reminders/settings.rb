#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  module Reminders
    class Settings < ::Pages::Page
      attr_reader :user

      def initialize(user)
        super()
        @user = user
      end

      def path
        edit_user_path(user, tab: :reminders)
      end

      def add_time
        page
          .click_button 'Add time'
      end

      def expect_active_daily_times(*times)
        times.each_with_index do |time, index|
          expect(page)
            .to have_css("input[data-qa-selector='op-settings-daily-time--active-#{index + 1}']:checked")

          expect(page)
            .to have_field("Time #{index + 1}", text: time)
        end
      end

      def save
        click_button 'Save'
      end
    end
  end
end
