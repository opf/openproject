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

feature 'resend invitation', type: :feature do
  let(:current_user) { FactoryGirl.create :admin }
  let(:user) { FactoryGirl.create :invited_user, mail: 'holly@openproject.com' }

  before do
    allow(User).to receive(:current).and_return current_user

    visit edit_user_path(user)
  end

  scenario 'admin resends the invitation' do
    click_on 'Resend invitation'

    expect(page).to have_text 'Another invitation has been sent to holly@openproject.com.'
  end

  context 'with some error occuring' do
    before do
      allow(UserInvitation).to receive(:token_action).and_return(nil)
    end

    scenario 'resending fails' do
      click_on 'Resend invitation'

      expect(page).to have_text 'An error occurred'
      expect(page).to have_text 'You are here: HomeAdministrationUsers'
    end
  end
end
