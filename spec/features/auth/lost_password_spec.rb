#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Lost password', type: :feature do
  let!(:user) { FactoryGirl.create :user }

  it 'shows same flash for invalid and existing users' do
    visit account_lost_password_path

    fill_in 'mail', with: 'invalid mail'
    click_on 'Submit'

    expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_account_lost_email_sent))

    expect(ActionMailer::Base.deliveries.size).to eql 0

    fill_in 'mail', with: user.mail
    click_on 'Submit'
    expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_account_lost_email_sent))
    expect(ActionMailer::Base.deliveries.size).to eql 1
  end
end
