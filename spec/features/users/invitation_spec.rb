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

require 'spec_helper'

feature 'invitation spec', type: :feature, js: true do
  using_shared_fixtures :admin
  let(:current_user) { admin }
  let(:user) { FactoryBot.create :invited_user, mail: 'holly@openproject.com' }

  before do
    allow(User).to receive(:current).and_return current_user

    visit edit_user_path(user)
  end

  scenario 'admin resends the invitation' do
    click_on I18n.t(:label_send_invitation)
    expect(page).to have_text 'An invitation has been sent to holly@openproject.com.'

    # Logout admin
    logout

    # Visit invitation with wrong token
    visit account_activate_path(token: 'some invalid value')
    expect(page).to have_text 'Invalid activation token'

    # Visit invitation link with correct token
    visit account_activate_path(token: Token::Invitation.last.value)

    expect(page).to have_selector('.op-modal--modal-header', text: 'Welcome to OpenProject')
  end
end
