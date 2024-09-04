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

RSpec.describe Principals::Scopes::OrderedByName do
  describe ".ordered_by_name" do
    shared_let(:anonymous) { User.anonymous }
    shared_let(:alice) { create(:user, login: "alice", firstname: "Alice", lastname: "Zetop") }
    shared_let(:eve) { create(:user, login: "eve", firstname: "Eve", lastname: "Baddie") }

    shared_let(:group) { create(:group, name: "Core Team") }
    shared_let(:placeholder_user) { create(:placeholder_user, name: "Developers") }

    subject { Principal.ordered_by_name(desc: descending).pluck(:id) }

    let(:descending) { false }

    shared_examples "sorted results" do
      it "returns the correct ascending sort" do
        expect(subject).to eq order
      end

      context "reversed" do
        let(:descending) { true }

        it "returns the correct descending sort" do
          expect(subject).to eq order.reverse
        end
      end
    end

    context "with default user sort", with_settings: { user_format: :firstname_lastname } do
      it_behaves_like "sorted results" do
        let(:order) { [alice.id, anonymous.id, group.id, placeholder_user.id, eve.id] }
      end
    end

    context "with lastname_firstname user sort", with_settings: { user_format: :lastname_firstname } do
      it_behaves_like "sorted results" do
        let(:order) { [anonymous.id, eve.id, group.id, placeholder_user.id, alice.id] }
      end
    end

    context "with lastname_n_firstname user sort", with_settings: { user_format: :lastname_n_firstname } do
      it_behaves_like "sorted results" do
        let(:order) { [anonymous.id, eve.id, group.id, placeholder_user.id, alice.id] }
      end
    end

    context "with lastname_coma_firstname user sort", with_settings: { user_format: :lastname_coma_firstname } do
      it_behaves_like "sorted results" do
        let(:order) { [anonymous.id, eve.id, group.id, placeholder_user.id, alice.id] }
      end
    end

    context "with firstname user sort", with_settings: { user_format: :firstname } do
      it_behaves_like "sorted results" do
        let(:order) { [alice.id, anonymous.id, group.id, placeholder_user.id, eve.id] }
      end
    end

    context "with login user sort", with_settings: { user_format: :username } do
      it_behaves_like "sorted results" do
        let(:order) { [alice.id, anonymous.id, group.id, placeholder_user.id, eve.id] }
      end
    end
  end
end
