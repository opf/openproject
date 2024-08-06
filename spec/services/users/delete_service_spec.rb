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

RSpec.describe Users::DeleteService, type: :model do
  let(:input_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }

  let(:instance) { described_class.new(model: input_user, user: actor) }

  subject { instance.call }

  shared_examples "deletes the user" do
    it do
      allow(input_user).to receive(:update_column).with(:status, 3)
      expect(Principals::DeleteJob).to receive(:perform_later).with(input_user)
      expect(subject).to be_success
      expect(input_user).to have_received(:update_column).with(:status, 3)
    end
  end

  shared_examples "does not delete the user" do
    it do
      allow(input_user).to receive(:update_column).with(:status, 3)
      expect(Principals::DeleteJob).not_to receive(:perform_later)
      expect(subject).not_to be_success
      expect(input_user).not_to have_received(:update_column).with(:status, 3)
    end
  end

  context "if deletion by admins allowed", with_settings: { users_deletable_by_admins: true } do
    context "with admin user" do
      let(:actor) { build_stubbed(:admin) }

      it_behaves_like "deletes the user"
    end

    context "with unprivileged system user" do
      let(:actor) { User.system }

      before do
        allow(actor).to receive(:admin?).and_return false
      end

      it_behaves_like "does not delete the user"
    end

    context "with privileged system user" do
      let(:actor) { User.system }

      it_behaves_like "deletes the user"
    end
  end

  context "if deletion by admins NOT allowed", with_settings: { users_deletable_by_admins: false } do
    context "with admin user" do
      let(:actor) { build_stubbed(:admin) }

      it_behaves_like "does not delete the user"
    end

    context "with system user" do
      let(:actor) { User.system }

      it_behaves_like "does not delete the user"
    end
  end
end
