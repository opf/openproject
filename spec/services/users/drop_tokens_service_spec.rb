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

RSpec.describe Users::DropTokensService, type: :model do
  shared_let(:input_user) { create(:user) }
  shared_let(:other_user) { create(:user) }

  let(:instance) { described_class.new(current_user: input_user) }

  subject { instance.call! }

  describe "Invitation token" do
    let!(:invitation_token) { create(:invitation_token, user: input_user) }
    let!(:other_invitation_token) { create(:invitation_token, user: other_user) }

    it "removes only the tokens from that user" do
      subject

      expect(Token::Invitation.exists?(invitation_token.id)).to be false
      expect(Token::Invitation.exists?(other_invitation_token.id)).to be true
    end
  end

  describe "Password reset token" do
    let!(:reset_token) { create(:recovery_token, user: input_user) }
    let!(:other_reset_token) { create(:recovery_token, user: other_user) }

    it "removes only the tokens from that user" do
      subject

      expect(Token::Recovery.exists?(reset_token.id)).to be false
      expect(Token::Recovery.exists?(other_reset_token.id)).to be true
    end
  end
end
