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

RSpec.describe "index users", :js, :with_cuprite do
  shared_let(:current_user) { create(:admin, firstname: "admin", lastname: "admin", created_at: 1.hour.ago) }
  let(:index_page) { Pages::Admin::Users::Index.new }

  before do
    login_as current_user
  end

  describe "with some sortable users" do
    let!(:a_user) { create(:user, login: "aa_login", firstname: "aa_first", lastname: "xxx_a") }
    let!(:b_user) { create(:user, login: "bb_login", firstname: "bb_first", lastname: "nnn_b") }
    let!(:z_user) { create(:user, login: "zz_login", firstname: "zz_first", lastname: "ccc_z") }

    it "sorts them correctly (Regression #35012)" do
      index_page.visit!
      index_page.expect_listed(current_user, a_user, b_user, z_user)

      index_page.order_by("First name")
      index_page.expect_order(a_user, current_user, b_user, z_user)

      index_page.order_by("First name")
      index_page.expect_order(z_user, b_user, current_user, a_user)

      index_page.order_by("Last name")
      index_page.expect_order(current_user, z_user, b_user, a_user)

      index_page.order_by("Last name")
      index_page.expect_order(a_user, b_user, z_user, current_user)
    end
  end

  describe "with some more status users" do
    shared_let(:anonymous) { create(:anonymous) }
    shared_let(:active_user) { create(:user, created_at: 1.minute.ago) }
    shared_let(:registered_user) { create(:user, status: User.statuses[:registered]) }
    shared_let(:invited_user) { create(:user, status: User.statuses[:invited]) }

    it "shows the users by status and allows status manipulations",
       with_settings: { brute_force_block_after_failed_logins: 5,
                        brute_force_block_minutes: 10 } do
      index_page.visit!

      # Order is by id, asc
      # so first ones created are on top.
      index_page.expect_listed(current_user, active_user, registered_user, invited_user)

      index_page.order_by("Created on")
      index_page.expect_order(invited_user, registered_user, active_user, current_user)

      index_page.order_by("Created on")
      index_page.expect_order(current_user, active_user, registered_user, invited_user)

      index_page.lock_user(active_user)
      index_page.expect_listed(current_user, active_user, registered_user, invited_user)
      index_page.expect_user_locked(active_user)

      expect(active_user.reload)
        .to be_locked

      index_page.filter_by_status("locked permanently")
      index_page.expect_listed(active_user)

      index_page.filter_by_status("active")
      index_page.expect_listed(current_user)

      index_page.filter_by_status("locked permanently")
      index_page.unlock_user(active_user)
      index_page.expect_non_listed

      index_page.filter_by_status("active")
      index_page.expect_listed(current_user, active_user)

      index_page.filter_by_name(active_user.lastname[0..-3])
      index_page.expect_listed(active_user)

      # temporarily block user
      active_user.update(failed_login_count: 6,
                         last_failed_login_on: 9.minutes.ago)
      index_page.clear_filters
      index_page.expect_listed(current_user, active_user, registered_user, invited_user)

      index_page.filter_by_status("locked temporarily")
      index_page.expect_listed(active_user)

      index_page.reset_failed_logins(active_user)
      index_page.expect_non_listed

      # temporarily block user and lock permanently
      active_user.reload
      active_user.update(failed_login_count: 6,
                         last_failed_login_on: 9.minutes.ago)
      index_page.clear_filters

      index_page.filter_by_status("locked temporarily")
      index_page.expect_listed(active_user)

      index_page.lock_user(active_user)
      index_page.expect_listed(active_user)

      index_page.filter_by_status("locked permanently")
      index_page.expect_listed(active_user)

      index_page.unlock_and_reset_user(active_user)
      index_page.expect_non_listed

      index_page.filter_by_status("active")
      index_page.expect_listed(current_user, active_user)

      # activate registered user
      index_page.filter_by_status("registered")
      index_page.expect_listed(registered_user)

      index_page.activate_user(registered_user)
      index_page.filter_by_status("active")

      index_page.expect_listed(current_user, active_user, registered_user)
    end

    context "as global user" do
      shared_let(:global_manage_user) { create(:user, global_permissions: [:manage_user]) }
      let(:current_user) { global_manage_user }

      it "can too visit the page" do
        index_page.visit!
        index_page.expect_listed(current_user, active_user, registered_user, invited_user)
      end
    end
  end
end
