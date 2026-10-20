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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Users::ChangePasswordService do
  let(:user) do
    create(:invited_user,
           password: old_password,
           password_confirmation: old_password)
  end
  let(:old_password) { "AdminAdmin42" }
  let(:new_password) { "SoreThroat33" }
  let(:session) { ActionController::TestSession.new }
  let(:instance) { described_class.new current_user: user, session: }

  let(:result) do
    instance.call new_password:, new_password_confirmation: new_password
  end

  it "is successful" do
    expect(result).to be_success
  end

  it "changes the user's password" do
    result
    expect(user.check_password?(old_password)).to be false
    expect(user.check_password?(new_password)).to be true
  end

  describe "activating the user" do
    context 'when the user is "invited"' do
      it "activates the user" do
        result
        expect(user).to be_active
      end
    end

    context 'when the user is not "invited"' do
      let(:user) do
        create(:locked_user,
               password: old_password,
               password_confirmation: old_password)
      end

      it "does not activate the user" do
        result
        expect(user).not_to be_active
      end
    end
  end

  context "with existing invitation tokens" do
    let!(:invitation_token) { create(:invitation_token, user:) }

    it "invalidates the existing token" do
      expect(result).to be_success
      expect(Token::Invitation.where(user:)).to be_empty
    end
  end

  context "with existing password recovery tokens" do
    let!(:recovery_token) { create(:recovery_token, user:) }

    it "invalidates the existing tokens" do
      expect(result).to be_success
      expect(Token::Recovery.where(user:)).to be_empty
    end
  end

  context "with existing remember-me tokens", with_settings: { autologin: 1 } do
    let!(:current_token) { create(:autologin_token, user:) }
    let!(:other_token) { create(:autologin_token, user:) }
    let!(:unrelated_token) { create(:autologin_token) }
    let!(:current_session) { create(:user_session, user:, session_id: session.id.private_id) }
    let!(:other_session) { create(:user_session, user:) }

    before do
      [[current_token, current_session], [other_token, other_session]].each do |token, user_session|
        Sessions::AutologinSessionLink.create!(
          token:,
          session: Sessions::UserSession.find_by!(session_id: user_session.session_id)
        )
      end
    end

    it "revokes remember-me tokens and other sessions while preserving the current session" do
      expect(result).to be_success

      expect(Token::AutoLogin.where(user:)).to be_empty
      expect(Sessions::AutologinSessionLink.where(token_id: [current_token.id, other_token.id])).to be_empty
      expect(Sessions::UserSession.for_user(user).pluck(:session_id)).to eq([current_session.session_id])
      expect(unrelated_token.reload).to be_persisted
    end

    context "when the password change fails" do
      let(:new_password) { "" }

      it "preserves remember-me tokens, links, and sessions" do
        expect(result).not_to be_success

        expect(Token::AutoLogin.where(user:).count).to eq(2)
        expect(Sessions::AutologinSessionLink.where(token_id: [current_token.id, other_token.id]).count).to eq(2)
        expect(Sessions::UserSession.for_user(user).count).to eq(2)
      end
    end
  end
end
