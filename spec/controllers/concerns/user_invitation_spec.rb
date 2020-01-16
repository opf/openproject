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

describe UserInvitation do
  describe '.placeholder_name' do
    it 'given an email it uses the local part as first and the domain as the last name' do
      email = 'xxxhunterxxx@openproject.com'
      first, last = UserInvitation.placeholder_name email

      expect(first).to eq 'xxxhunterxxx'
      expect(last).to eq '@openproject.com'
    end

    it 'trims names if they are too long (> 30 characters)' do
      email = 'hallowurstsalatgetraenkebuechse@veryopensuchproject.openproject.com'
      first, last = UserInvitation.placeholder_name email

      expect(first).to eq 'hallowurstsalatgetraenkebue...'
      expect(last).to eq '@veryopensuchproject.openpro...'
    end
  end

  describe '.reinvite_user' do
    let(:user) { FactoryBot.create :invited_user }
    let!(:token) { FactoryBot.create :invitation_token, user: user }

    it 'notifies listeners of the re-invite' do
      expect(OpenProject::Notifications).to receive(:send) do |event, new_token|
        expect(event).to eq 'user_reinvited'
      end

      UserInvitation.reinvite_user user.id
    end

    it 'creates a new token' do
      new_token = UserInvitation.reinvite_user user.id

      expect(new_token.value).not_to eq token.value
      expect(Token::Invitation.exists?(token.id)).to eq false
    end
  end
end
