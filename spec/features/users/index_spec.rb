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

require "spec_helper"

RSpec.describe "index users", :js do
  shared_let(:admin) { create(:admin, firstname: "admin", lastname: "admin", created_at: 1.hour.ago) }
  let(:current_user) { admin }
  let(:index_page) { Pages::Admin::Users::Index.new }

  before do
    login_as current_user
  end

  describe "filtering", :js do
    let!(:alice) { create(:user, login: "alice", firstname: "Alice", lastname: "Smith") }
    let!(:bob)   { create(:user, login: "bob",   firstname: "Bob",   lastname: "Jones") }
    let!(:my_group) { create(:group, lastname: "My group", members: [alice]) }

    it "filters by name via the search input and updates without a page reload" do
      index_page.visit!
      index_page.expect_listed(current_user, alice, bob)

      index_page.filter_by_name("Alice")
      index_page.expect_listed(alice)
    end

    it "allows changing the status filter away from the default active-only view" do
      registered = create(:user, login: "charlie", status: User.statuses[:registered])

      index_page.visit!
      # Default: only active users
      index_page.expect_listed(current_user, alice, bob)
      expect(page).to have_no_css("td.username a", text: registered.login)

      index_page.filter_by_status(I18n.t(:status_registered))
      index_page.expect_listed(registered)
    end

    it "filters by group and keeps that filter after reload" do
      index_page.visit!
      expect(page).to have_css("td.username a", text: alice.login)
      expect(page).to have_css("td.username a", text: bob.login)

      index_page.filter_by_group("My group")
      index_page.expect_listed(alice)
      index_page.expect_not_listed(bob)

      page.refresh

      index_page.expect_group_filter("My group")
      index_page.expect_listed(alice)
      index_page.expect_not_listed(bob)
    end
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

    it "shows active users by default and allows status filtering and manipulations",
       with_settings: { brute_force_block_after_failed_logins: 5,
                        brute_force_block_minutes: 10 } do
      index_page.visit!

      # Default filter: active users only
      index_page.expect_listed(current_user, active_user)

      index_page.lock_user(active_user)
      expect(active_user.reload).to be_locked

      index_page.filter_by_status(I18n.t(:status_locked))
      index_page.expect_listed(active_user)
      index_page.expect_user_locked(active_user)

      index_page.filter_by_status(I18n.t(:status_active))
      index_page.expect_listed(current_user)

      index_page.filter_by_status(I18n.t(:status_locked))
      index_page.unlock_user(active_user)
      index_page.expect_non_listed

      index_page.filter_by_status(I18n.t(:status_active))
      index_page.expect_listed(current_user, active_user)

      index_page.filter_by_name(active_user.lastname[0..-3])
      index_page.expect_listed(active_user)

      # temporarily block user — reset via action, no filter needed
      active_user.update(failed_login_count: 6,
                         last_failed_login_on: 9.minutes.ago)
      index_page.clear_filters
      # after clear, default active filter is restored
      index_page.expect_listed(current_user, active_user)

      index_page.reset_failed_logins(active_user)
      # still listed — reset doesn't change status
      index_page.expect_listed(current_user, active_user)

      # Lock and unlock — failed logins were reset above, so the user is locked
      # but not blocked, and the row exposes the plain "Unlock" action.
      index_page.lock_user(active_user)
      index_page.filter_by_status(I18n.t(:status_locked))
      index_page.expect_listed(active_user)

      index_page.unlock_user(active_user)
      index_page.expect_non_listed

      index_page.filter_by_status(I18n.t(:status_active))
      index_page.expect_listed(current_user, active_user)

      # activate registered user
      index_page.filter_by_status(I18n.t(:status_registered))
      index_page.expect_listed(registered_user)

      index_page.activate_user(registered_user)
      index_page.filter_by_status(I18n.t(:status_active))
      index_page.expect_listed(current_user, active_user, registered_user)
    end

    context "as global user" do
      # :manage_user declares :view_all_principals as a dependency in the
      # access-control map; the factory does not auto-expand dependencies, so we
      # add it explicitly to match real-world role configuration.
      shared_let(:global_manage_user) do
        create(:user, global_permissions: %i[manage_user view_all_principals])
      end
      let(:current_user) { global_manage_user }

      it "can too visit the page" do
        index_page.visit!
        index_page.expect_listed(admin, current_user, active_user)
      end
    end
  end
end
