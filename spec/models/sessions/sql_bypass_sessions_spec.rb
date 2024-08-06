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

RSpec.describe Sessions::SqlBypass do
  subject { build(:user_session, user:) }

  shared_examples "augments the user_id attribute" do
    it do
      subject.save
      expect(subject.data["user_id"]).to eq(user_id)
    end
  end

  describe "when user_id is present" do
    let(:user) { build_stubbed(:user) }
    let(:user_id) { user.id }

    it_behaves_like "augments the user_id attribute"
  end

  describe "when user_id is nil" do
    let(:user) { nil }
    let(:user_id) { nil }

    it_behaves_like "augments the user_id attribute"
  end
end
