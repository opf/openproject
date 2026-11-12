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

require_relative "../../spec_helper"

RSpec.describe Avatars::UpdateService do
  let(:user_without_avatar) { build_stubbed(:user) }
  let(:user_with_avatar) do
    u = create(:user)
    u.attachments = [build(:avatar_attachment, author: u)]
    u
  end

  let(:instance) { described_class.new user }

  describe "replace" do
  end

  describe "delete" do
    subject { instance.destroy }

    context "user has avatar" do
      let(:user) { user_with_avatar }

      it "destroys the attachment" do
        expect_any_instance_of(Attachment).to receive(:destroy).and_return true
        expect(subject).to be_success
      end
    end

    context "user has no avatar" do
      let(:user) { user_without_avatar }

      it "returns an error" do
        expect(subject).not_to be_success
        expect(subject.errors[:base]).to include I18n.t(:unable_to_delete_avatar)
      end
    end
  end
end
