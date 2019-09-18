#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe 'index users', type: :feature do
  let!(:admin) { FactoryBot.create :admin, created_on: 1.hour.ago }
  let!(:anonymous) { FactoryBot.create :anonymous }
  let!(:active_user) { FactoryBot.create :user, created_on: 1.minute.ago }
  let!(:registered_user) { FactoryBot.create :user, status: User::STATUSES[:registered] }
  let!(:invited_user) { FactoryBot.create :user, status: User::STATUSES[:invited] }
  let(:index_page) { Pages::Admin::Users::Index.new }

  before do
    login_as(admin)
  end

  it 'shows the users by status and allows status manipulations',
     with_settings: { brute_force_block_after_failed_logins: 5,
                      brute_force_block_minutes: 10 } do
    index_page.visit!

    # Order is by id, asc
    # so first ones created are on top.
    index_page.expect_listed(admin, active_user, registered_user, invited_user)

    index_page.order_by('Created on')
    index_page.expect_listed(invited_user, registered_user, active_user, admin)

    index_page.order_by('Created on')
    index_page.expect_listed(admin, active_user, registered_user, invited_user)

    index_page.lock_user(active_user)
    index_page.expect_listed(admin, active_user, registered_user, invited_user)
    index_page.expect_user_locked(active_user)

    expect(active_user.reload)
      .to be_locked

    index_page.filter_by_status('locked permanently (1)')
    index_page.expect_listed(active_user)

    index_page.filter_by_status('active (1)')
    index_page.expect_listed(admin)

    index_page.filter_by_status('locked permanently (1)')
    index_page.unlock_user(active_user)
    index_page.expect_non_listed

    index_page.filter_by_status('active (2)')
    index_page.expect_listed(admin, active_user)

    index_page.filter_by_name(active_user.lastname[0..-3])
    index_page.expect_listed(active_user)

    # temporarily block user
    active_user.update_attributes(failed_login_count: 6,
                                  last_failed_login_on: 9.minutes.ago)
    index_page.clear_filters
    index_page.expect_listed(admin, active_user, registered_user, invited_user)

    index_page.filter_by_status('locked temporarily (1)')
    index_page.expect_listed(active_user)

    index_page.reset_failed_logins(active_user)
    index_page.expect_non_listed

    # temporarily block user and lock permanently
    active_user.reload
    active_user.update_attributes(failed_login_count: 6,
                                  last_failed_login_on: 9.minutes.ago)
    index_page.clear_filters

    index_page.filter_by_status('locked temporarily (1)')
    index_page.expect_listed(active_user)

    index_page.lock_user(active_user)
    index_page.expect_listed(active_user)

    index_page.filter_by_status('locked permanently (1)')
    index_page.expect_listed(active_user)

    index_page.unlock_and_reset_user(active_user)
    index_page.expect_non_listed

    index_page.filter_by_status('active (2)')
    index_page.expect_listed(admin, active_user)

    # activate registered user
    index_page.filter_by_status('registered (1)')
    index_page.expect_listed(registered_user)

    index_page.activate_user(registered_user)
    index_page.filter_by_status('active (3)')

    index_page.expect_listed(admin, active_user, registered_user)
  end
end
