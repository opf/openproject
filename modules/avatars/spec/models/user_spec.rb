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

require_relative "../spec_helper"
require_relative "../shared_examples"

RSpec.describe User do
  let(:user) { build(:user) }

  include_examples "there are users with and without avatars"

  specify { expect(user.attachments).to all be_a Attachment }

  describe "#local_avatar_attachment" do
    subject { user.local_avatar_attachment }

    context "when user has an avatar" do
      let(:user) { user_with_avatar }

      it { is_expected.to be_a Attachment }
    end

    context "when user has no avatar" do
      let(:user) { user_without_avatar }

      it { is_expected.to be_blank }
    end
  end

  describe "#local_avatar_attachment=" do
    context "when the uploaded file is a good image" do
      subject { lambda { user.local_avatar_attachment = avatar_file } }

      specify { expect { subject.call }.not_to raise_error }
      specify { expect { subject.call }.to change(user, :local_avatar_attachment) }
    end
  end
end
