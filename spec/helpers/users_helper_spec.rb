#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UsersHelper, type: :helper do
  include UsersHelper

  def build_user(status, blocked)
    user = FactoryGirl.build(:user)
    allow(user).to receive(:status).and_return(User::STATUSES[status])
    allow(user).to receive(:failed_too_many_recent_login_attempts?).and_return(blocked)
    allow(user).to receive(:failed_login_count).and_return(3)
    user
  end

  describe 'full_user_status' do
    test_cases = {
      [:active, false] => I18n.t(:active, scope: :user),
      [:active, true] => I18n.t(:blocked_num_failed_logins,
                                count: 3,
                                scope: :user),
      [:locked, false] => I18n.t(:locked, scope: :user),
      [:locked, true] => I18n.t(:status_user_and_brute_force,
                                user: I18n.t(:locked, scope: :user),
                                brute_force: I18n.t(:blocked_num_failed_logins,
                                                    count: 3,
                                                    scope: :user),
                                scope: :user),
      [:registered, false] => I18n.t(:registered, scope: :user),
      [:registered, true] => I18n.t(:status_user_and_brute_force,
                                    user: I18n.t(:registered, scope: :user),
                                    brute_force: I18n.t(:blocked_num_failed_logins,
                                                        count: 3,
                                                        scope: :user),
                                    scope: :user)
    }

    test_cases.each do |(status, blocked), expectation|
      describe "with status #{status} and blocked #{blocked}" do
        before do
          user = build_user(status, blocked)
          @status = full_user_status(user, true)
        end

        it "should return #{expectation}" do
          expect(@status).to eq(expectation)
        end
      end
    end
  end

  describe 'change_user_status_buttons' do
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
        before do
          user = build_user(status, blocked)
          @buttons = change_user_status_buttons(user)
        end
        it "should contain '#{expectation}'" do
          expect(@buttons).to include(expectation)
        end

        it 'should contain a single button' do
          expect(@buttons.scan('<input').count).to eq(1)
        end
      end
    end

    describe 'with status active and blocked True' do
      before do
        user = build_user(:active, true)
        @buttons = change_user_status_buttons(user)
      end

      it 'should return inputs (buttons)' do
        expect(@buttons.scan('<input').count).to eq(2)
      end

      it "should contain 'Lock' and 'Reset Failed logins'" do
        expect(@buttons).to include(I18n.t(:lock, scope: :user))
        expect(@buttons).to include(I18n.t(:reset_failed_logins, scope: :user))
      end
    end
  end
end
