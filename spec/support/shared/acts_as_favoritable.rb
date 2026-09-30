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

RSpec.shared_examples_for "acts_as_favoritable included" do
  shared_let(:favoriting_user) { create(:user) }
  shared_let(:other_user) { create(:user) }

  before do
    Favorite.create(user: favoriting_user, favorited: instance)
  end

  it { is_expected.to have_many(:favorites).dependent(:delete_all) }
  it { is_expected.to have_many(:favoriting_users).through(:favorites) }

  describe ".favorited_by" do
    it "returns instance for favoriting user" do
      expect(described_class.favorited_by(favoriting_user).to_a).to eq [instance]
    end

    it "returns no instance for non favoriting user" do
      expect(described_class.favorited_by(other_user).to_a).not_to eq [instance]
    end
  end

  describe ".with_favorited_by_user" do
    subject { described_class.with_favorited_by_user(user).to_a }

    context "for favoriting user" do
      let(:user) { favoriting_user }

      it "returns instance for favoriting user" do
        expect(subject).to eq [instance]
      end

      it "marks instance as favorited" do
        expect(subject).to all(have_attributes(favorited: true))
      end
    end

    context "for non favoriting user" do
      let(:user) { other_user }

      it "returns instance for favoriting user" do
        expect(subject).to eq [instance]
      end

      it "marks instance as not favorited" do
        expect(subject).to all(have_attributes(favorited: false))
      end
    end
  end

  describe "#add_favoriting_user" do
    context "for favoriting user" do
      let(:user) { favoriting_user }

      it "does nothing" do
        expect do
          instance.add_favoriting_user(user)
        end.not_to change { described_class.favorited_by(user).to_a }.from([instance])
      end
    end

    context "for non favoriting user" do
      let(:user) { other_user }

      it "adds to favorites" do
        expect do
          instance.add_favoriting_user(user)
        end.to change { described_class.favorited_by(user).to_a }.from([]).to([instance])
      end
    end
  end

  describe "#remove_favoriting_user" do
    context "for favoriting user" do
      let(:user) { favoriting_user }

      it "removes from favorites" do
        expect do
          instance.remove_favoriting_user(user)
        end.to change { described_class.favorited_by(user).to_a }.from([instance]).to([])
      end
    end

    context "for non favoriting user" do
      let(:user) { other_user }

      it "does nothing" do
        expect do
          instance.remove_favoriting_user(user)
        end.not_to change { described_class.favorited_by(user).to_a }
      end
    end
  end

  describe "#set_favorited" do
    before do
      allow(instance).to receive(:add_favoriting_user)
      allow(instance).to receive(:remove_favoriting_user)
    end

    it "calls add_favoriting_user by default" do
      instance.set_favorited(favoriting_user)

      expect(instance).to have_received(:add_favoriting_user).with(favoriting_user)
      expect(instance).not_to have_received(:remove_favoriting_user)
    end

    it "calls add_favoriting_user when called with favorited: true" do
      instance.set_favorited(favoriting_user, favorited: true)

      expect(instance).to have_received(:add_favoriting_user).with(favoriting_user)
      expect(instance).not_to have_received(:remove_favoriting_user)
    end

    it "calls remove_favoriting_user when called with favorited: false" do
      instance.set_favorited(favoriting_user, favorited: false)

      expect(instance).not_to have_received(:add_favoriting_user)
      expect(instance).to have_received(:remove_favoriting_user).with(favoriting_user)
    end
  end

  describe "#favorited_by?" do
    it "returns true for favoriting user" do
      expect(instance).to be_favorited_by(favoriting_user)
    end

    it "returns false for non favoriting user" do
      expect(instance).not_to be_favorited_by(other_user)
    end
  end
end
