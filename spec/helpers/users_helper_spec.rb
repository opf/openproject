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

require "spec_helper"

RSpec.describe UsersHelper do
  def build_user(status, blocked)
    build_stubbed(:user,
                  status:,
                  failed_login_count: 3).tap do |user|
      allow(user)
        .to receive(:failed_too_many_recent_login_attempts?)
        .and_return(blocked)
    end
  end

  describe "full_user_status" do
    test_cases = {
      [:active, false] => I18n.t("user.active"),
      [:active, true] => I18n.t("user.blocked_num_failed_logins",
                                count: 3),
      [:locked, false] => I18n.t("user.locked"),
      [:locked, true] => I18n.t("user.status_user_and_brute_force",
                                user: I18n.t("user.locked"),
                                brute_force: I18n.t("user.blocked_num_failed_logins",
                                                    count: 3)),
      [:registered, false] => I18n.t("user.registered"),
      [:registered, true] => I18n.t("user.status_user_and_brute_force",
                                    user: I18n.t("user.registered"),
                                    brute_force: I18n.t("user.blocked_num_failed_logins",
                                                        count: 3))
    }

    test_cases.each do |(status, blocked), expectation|
      describe "with status #{status} and blocked #{blocked}" do
        let(:user) { build_user(status, blocked) }

        subject(:user_status) do
          full_user_status(user, true)
        end

        it "returns #{expectation}" do
          expect(user_status).to eq(expectation)
        end
      end
    end
  end

  describe "change_user_status_buttons" do
    test_cases = {
      [:active, false] => :lock,
      [:locked, false] => :unlock,
      [:locked, true] => :unlock_and_reset_failed_logins,
      [:registered, false] => :activate,
      [:registered, true] => :activate_and_reset_failed_logins
    }

    test_cases.each do |(status, blocked), expectation_symbol|
      describe "with status #{status} and blocked #{blocked}" do
        expectation = I18n.t(expectation_symbol, scope: :user)
        subject(:buttons) do
          user = build_user(status, blocked)
          change_user_status_buttons(user)
        end

        it "contains '#{expectation}'" do
          expect(buttons).to include(expectation)
        end

        it "contains a single button" do
          expect(buttons.scan("<button").count).to eq(1)
        end
      end
    end

    describe "with status active and blocked True" do
      subject(:buttons) do
        user = build_user(:active, true)
        change_user_status_buttons(user)
      end

      it "returns inputs (buttons)" do
        expect(buttons.scan("<button").count).to eq(2)
      end

      it "contains 'Lock' and 'Reset Failed logins'" do
        expect(buttons).to include(I18n.t("user.lock"))
        expect(buttons).to include(I18n.t("user.reset_failed_logins"))
      end
    end
  end
end
