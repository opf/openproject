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

RSpec.describe Users::DeleteService, "Integration", type: :model do
  let(:input_user) { create(:user) }
  let(:actor) { build_stubbed(:admin) }

  let(:instance) { described_class.new(model: input_user, user: actor) }

  subject { instance.call }

  context "when input user is invalid",
          with_settings: { users_deletable_by_admins: true } do
    before do
      input_user.update_column(:mail, "")
    end

    it "can still delete the user" do
      expect(input_user).not_to be_valid

      expect(subject).to be_success

      expect(Principals::DeleteJob).to have_been_enqueued.with(input_user)
    end
  end
end
