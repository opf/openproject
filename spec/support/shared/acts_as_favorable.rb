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

RSpec.shared_examples_for "acts_as_favorable included" do
  shared_let(:favoring_user) { create(:user) }
  shared_let(:other_user) { create(:user) }

  before do
    Favorite.create(user: favoring_user, favored: instance)
  end

  it { is_expected.to have_many(:favorites).dependent(:delete_all) }
  it { is_expected.to have_many(:favoring_users).through(:favorites) }

  describe ".favored_by" do
    it "returns instance for favoring user" do
      expect(described_class.favored_by(favoring_user).to_a).to eq [instance]
    end

    it "returns no instance for non favoring user" do
      expect(described_class.favored_by(other_user).to_a).not_to eq [instance]
    end
  end

  describe ".with_favored_by_user" do
    subject { described_class.with_favored_by_user(user).to_a }

    context "for favoring user" do
      let(:user) { favoring_user }

      it "returns instance for favoring user" do
        expect(subject).to eq [instance]
      end

      it "marks instance as favored" do
        expect(subject).to all(have_attributes(favored: true))
      end
    end

    context "for non favoring user" do
      let(:user) { other_user }

      it "returns instance for favoring user" do
        expect(subject).to eq [instance]
      end

      it "marks instance as not favored" do
        expect(subject).to all(have_attributes(favored: false))
      end
    end
  end

  describe "#add_favoring_user" do
    context "for favoring user" do
      let(:user) { favoring_user }

      it "does nothing" do
        expect do
          instance.add_favoring_user(user)
        end.not_to change { described_class.favored_by(user).to_a }.from([instance])
      end
    end

    context "for non favoring user" do
      let(:user) { other_user }

      it "adds to favorites" do
        expect do
          instance.add_favoring_user(user)
        end.to change { described_class.favored_by(user).to_a }.from([]).to([instance])
      end
    end
  end

  describe "#remove_favoring_user" do
    context "for favoring user" do
      let(:user) { favoring_user }

      it "removes from favorites" do
        expect do
          instance.remove_favoring_user(user)
        end.to change { described_class.favored_by(user).to_a }.from([instance]).to([])
      end
    end

    context "for non favoring user" do
      let(:user) { other_user }

      it "does nothing" do
        expect do
          instance.remove_favoring_user(user)
        end.not_to change { described_class.favored_by(user).to_a }
      end
    end
  end

  describe "#set_favored" do
    before do
      allow(instance).to receive(:add_favoring_user)
      allow(instance).to receive(:remove_favoring_user)
    end

    it "calls add_favoring_user by default" do
      instance.set_favored(favoring_user)

      expect(instance).to have_received(:add_favoring_user).with(favoring_user)
      expect(instance).not_to have_received(:remove_favoring_user)
    end

    it "calls add_favoring_user when called with favored: true" do
      instance.set_favored(favoring_user, favored: true)

      expect(instance).to have_received(:add_favoring_user).with(favoring_user)
      expect(instance).not_to have_received(:remove_favoring_user)
    end

    it "calls remove_favoring_user when called with favored: false" do
      instance.set_favored(favoring_user, favored: false)

      expect(instance).not_to have_received(:add_favoring_user)
      expect(instance).to have_received(:remove_favoring_user).with(favoring_user)
    end
  end

  describe "#favored_by?" do
    it "returns true for favoring user" do
      expect(instance).to be_favored_by(favoring_user)
    end

    it "returns false for non favoring user" do
      expect(instance).not_to be_favored_by(other_user)
    end
  end
end
